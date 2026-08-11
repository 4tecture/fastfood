# Setup Certificates

Check the following [Link](https://docs.dapr.io/operations/security/mtls/#bringing-your-own-certificates-1) to get the tools and instructions.

These certificates are local development material. Never commit generated keys or `mtls.env`.

Generate a fresh set before starting Docker Compose:

```bash
./generate.sh
```

PowerShell users can let `src/start-compose.ps1` generate the certificates, or
generate them with `step` under `generated/` and then run
`./generate-env.ps1 -CertsPath ./generated`. All files under `generated/` are
ignored by Git; the Bash generator restricts keys to the current user.

The Compose launchers reuse a complete existing certificate set so they do not
invalidate running sidecars. Set `FASTFOOD_ROTATE_CERTIFICATES=true` before
launching Compose when you intentionally want to rotate it.

If a private key was ever pushed to a remote repository, removing the file in a
later commit is not sufficient: rotate the key and purge it from repository
history according to your organization’s incident-response process.

```bash
mkdir -p generated
step certificate create cluster.local generated/ca.crt generated/ca.key --profile root-ca --no-password --insecure
step certificate create cluster.local generated/issuer.crt generated/issuer.key --ca generated/ca.crt --ca-key generated/ca.key --profile intermediate-ca --not-after 8760h --no-password --insecure
```
