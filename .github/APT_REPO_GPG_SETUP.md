# APT Repository GPG Setup for GitHub Actions

This guide explains how to generate, store, and use a GPG key for signing the APT repository deployed by GitHub Actions.

## GPG Keys and APT Repositories
APT repositories use GPG keys to sign metadata (`Release` files). This provides verification of origin and ensures that the repository contents have not been tampered with. The `build-packages.yml` workflow automatically signs the repository metadata whenever new packages are built.

## 1. Generating a GPG Key
If you don't already have a dedicated GPG key for signing the packages, you can create one using the following command on your local machine:

```bash
gpg --full-generate-key
```

Follow the prompts:
- Select `(1) RSA and RSA` (default).
- Choose a key size (4096 is recommended for high security).
- Choose how long the key should be valid (e.g., `0` for never expires).
- Enter the name and email (e.g., "Scorpia Labs APT Signer", "admin@scorpia-labs.com").

### Passphrase Tradeoffs
You will be prompted to enter a passphrase. There is a tradeoff depending on your choice:
- **No Passphrase (Unencrypted Key):** If you leave the passphrase empty, the private key is not encrypted. It is easier to use in automated pipelines (GitHub Actions) because you only need to store the private key, and no passphrase is required to sign files. GitHub Secrets encrypts your keys at rest, so storing an unencrypted key in GitHub Secrets is generally safe for this purpose.
- **With a Passphrase (Encrypted Key):** If you provide a passphrase, the key is encrypted. This provides an additional layer of security in case the key is ever leaked. However, you will need to store both the private key and the passphrase as separate GitHub Secrets and pass the passphrase during the workflow run.

## 2. Exporting the GPG Private Key
Once the key is generated, you need to export the private key to add it to GitHub Secrets.

First, list your keys to get the Key ID:
```bash
gpg --list-secret-keys --keyid-format LONG
```
The Key ID will be a string like `3AA5C34371567BD2`.

Export the private key using the Key ID:
```bash
gpg --armor --export-secret-keys 3AA5C34371567BD2 > private-key.asc
```

## 3. Adding Secrets to GitHub
Go to your repository on GitHub: `Settings` > `Secrets and variables` > `Actions` > `New repository secret`.

- **Name:** `GPG_PRIVATE_KEY`
- **Secret:** Paste the entire contents of the `private-key.asc` file (including the `-----BEGIN PGP PRIVATE KEY BLOCK-----` and `-----END PGP PRIVATE KEY BLOCK-----` lines).

If you chose to use a passphrase for your key, create another secret:
- **Name:** `GPG_PASSPHRASE`
- **Secret:** The passphrase you set for the GPG key.

*Note: The GitHub Actions workflow is configured to automatically check for the `GPG_PASSPHRASE` secret. If you created a key without a passphrase, you do not need to set the `GPG_PASSPHRASE` secret.*

## 4. How Users Use the Key
The GitHub Actions workflow automatically exports the public GPG key to `scorpia-labs.gpg.key` inside the APT repository directory (`apt/noble/scorpia-labs.gpg.key`).

Users who want to use your APT repository can download and install this key:
```bash
curl -fsSL https://scorpia-labs.github.io/apt/noble/scorpia-labs.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/scorpia-labs.gpg
```
They will then configure the APT source to use this key:
```bash
echo "deb [signed-by=/etc/apt/keyrings/scorpia-labs.gpg] https://scorpia-labs.github.io/apt/noble /" | sudo tee /etc/apt/sources.list.d/scorpia-labs.list
```
