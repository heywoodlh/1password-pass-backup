#!/usr/bin/env bash

if [[ $# -lt 2 ]]
then
  printf "Usage: %s <gpg-recipient> <password-store-dir>\n" "${0}"
  exit 1
fi

gpg_target="${1}"
password_store_dir="${2}"

if ! gpg --list-keys | grep -q "${gpg_target}"
then
    echo "GPG recipient ${gpg_target} not found in keyring"
    exit 1
fi

mkdir -p "${password_store_dir}"

# Sign in to 1Password
env | grep -iqE "^OP_SESSION" || eval "$(op signin)"

# Get all vaults
vault_json=$(op vault list --format=json)
vault_ids=$(printf "%s" "${vault_json}" | jq -r '.[].id')

# Get all items in all vaults
for vault in ${vault_ids}
do
  vault_name=$(printf "%s" "${vault_json}" | jq -r '.[] | select(.id == "'${vault}'") | .name' | sed 's/ /_/g')
  item_json="$(op item ls --vault ${vault} --format json | op item get --format json - | jq -rc)"
  while read item
  do
    id="$(echo "${item}" | jq -r '.id')"
    title="$(echo "${item}" | jq -r '.title')"
    category="$(echo "${item}" | jq -r '.category')"
    filename="${password_store_dir}/${vault_name}/${title}.gpg"
    mkdir -p "$(dirname "${filename}")"
    username=""
    password=""
    otp=""
    pretty_item="$(echo "${item}" | jq '.' 2>/dev/null)"
    if [[ -n ${pretty_item} ]]
    then
      if [[ "${category}" == "SSH_KEY" ]]
      then
        echo "creating => ${filename}"
        printf "%s" "${item}" | gpg --batch --yes -r "${gpg_target}" --encrypt -o "${filename}"
      else
        username=$(printf "%s" "${item}" | jq -r '.fields[] | select(.label == "username") | .value' | head -1 2>/dev/null)
        password=$(printf "%s" "${item}" | jq -r '.fields[] | select(.label == "password") | .value' | head -1 2>/dev/null)
        printf "%s" "${item}" | grep -q 'OTP' && otp=$(printf "%s" "${item}" | jq -r '.fields[] | select(.type == "OTP") | .value' | sed 's/ //g')
        [[ -n "${otp}" ]] && otp="otpauth://totp/${id}?secret=${otp}&issuer=totp-secret"
        echo "creating => ${filename}"
        printf "%s\n%s\nfull_item: \n%s\n" "${password}" "${otp}" "${pretty_item}" | gpg --batch --yes -r "${gpg_target}" --encrypt -o "${filename}"
      fi
    fi
  done <<< "${item_json}"
done
