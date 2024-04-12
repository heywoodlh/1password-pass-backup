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
  item_json="$(op item list --vault "${vault}" --format=json | jq -r -c '.[] | {id: .id, title: (.title | gsub(" "; "_")), category: .category}')"
  for item in ${item_json}
  do
    id="$(echo "${item}" | jq -r '.id')"
    title="$(echo "${item}" | jq -r '.title')"
    category="$(echo "${item}" | jq -r '.category')"
    filename="${password_store_dir}/${vault_name}/${title}.gpg"
    mkdir -p "$(dirname "${filename}")"
    item_json=$(op item get --vault "${vault}" "${id}" --format=json)
    #fields=$(printf "%s" "${item_json}" | jq -cr '.fields[] | {id: .id, type: .type, label: .label, value: .value}')
    username=""
    password=""
    otp=""
    if [[ "${category}" == "SSH_KEY" ]]
    then
      echo "creating => ${filename}"
      printf "%s" "${item_json}" | gpg --batch --yes -r "${gpg_target}" --encrypt -o "${filename}"
    else
      username=$(printf "%s" "${item_json}" | op item get - --fields label=username 2>/dev/null)
      password=$(printf "%s" "${item_json}" | op item get - --fields label=password 2>/dev/null)
      printf "%s" "${item_json}" | grep -q 'OTP' && otp=$(printf "%s" "${item_json}" | op item get - --fields type=OTP --format=json | jq -r '.value' | sed 's/ //g')
      [[ -n "${otp}" ]] && otp="otpauth://totp/${id}?secret=${otp}&issuer=totp-secret"
      echo "creating => ${filename}"
      printf "%s\n%s\nfull_item: \n%s\n" "${password}" "${otp}" "${item_json}" | gpg --batch --yes -r "${gpg_target}" --encrypt -o "${filename}"
    fi
  done
done
