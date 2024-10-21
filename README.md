## 1Password GPG/Password Store Backup

This is a simple BASH script that backs up your 1Password data with GPG in a
file format that works with [pass](https://www.passwordstore.org/).

## Dependencies

The following requirements should be met:
1. 1Password CLI is configured and installed
2. A target GPG public key is available to encrypt the backup

## Usage:

```
./backup.sh gpg-id path/to/1password-backup-dir
```

Depending on how many items you have, it may take a while, as this script will
use the 1Password CLI to export each item individually.

Assuming you invoked `backup.sh` like this:

```
./backup.sh myemail@heywoodlh.io /tmp/1password-backup
```

The script will start creating a backup and will output filenames it creates in
this format:

```
creating => /tmp/1password-backup/$VAULT_NAME/$ITEM_NAME.gpg
```

You can then decrypt the file with your GPG private key, like this:

```
gpg --decrypt /tmp/1password-backup/$VAULT_NAME/$ITEM_NAME.gpg
```

And this is the resulting format (password is line 1, OTP is line 2 and the
original content is the rest of the file):

```
yourawesomepassword
otpauth://totp/someid?secret=SOMETOTPSECRET&issuer=totp-secret
full_item:
{
  "id": "someid",
  "title": "sometitle",
  "version": 3,
  "vault": {
    "id": "someid",
    "name": "somevault"
  },
...
```

### Pass usage

Retrieve password:

```
PASSWORD_STORE_DIR=/tmp/1password-backup pass <someitem> | head -1
```

Retrieve OTP (with the [pass-otp plugin](https://github.com/tadfisher/pass-otp) installed):

```
PASSWORD_STORE_DIR=/tmp/1password-backup pass otp <someitem>
```

Retrieve the entire item:

```
PASSWORD_STORE_DIR=/tmp/1password-backup pass <someitem>
```
