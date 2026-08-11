# Create testing certificates

Install `mkcert` (for example, `brew install mkcert`) and trust its local CA
once with `mkcert -install`. The Compose launcher then calls `./generate.sh`
or `./generate.ps1` when the ignored certificate files are missing.

These files are only for a trusted development workstation. Never commit the
generated private key or use it in a shared environment.
