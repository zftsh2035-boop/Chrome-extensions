# Security and signing

Never commit an Android signing keystore or its password to this repository.

The release workflow expects these GitHub Actions secrets:

- `ANDROID_KEYSTORE_B64`: base64 of the complete PKCS#12/JKS file;
- `ANDROID_KEYSTORE_PASSWORD`: keystore password;

The non-secret key alias is fixed in the workflow as
`chromium_armv7_extensions`.

The same signing key and package name must be used for every release. If the
key is lost or changed, Android will reject an in-place update and the existing
app must be uninstalled, which deletes its local browser profile.

The initial key is stored outside GitHub in a private checkpoint. Its SHA-256
certificate fingerprint is:

`90:26:67:30:E9:8C:8A:40:C5:36:94:F0:6C:33:AB:82:01:96:8A:FE:A0:39:E3:CE:73:47:FD:7F:42:EA:D4:F2`
