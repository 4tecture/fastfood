# GitHub issue evidence images

GitHub has no public token-based API for creating `user-attachments` URLs. For an API-only,
private-repository-safe demo, store evidence on a dedicated `copilot-demo-evidence` branch and
reference its authenticated `github.com/.../raw/...` URL.

This workflow follows GitHub's
[awesome-copilot image guidance](https://github.com/github/awesome-copilot/blob/main/skills/github-issues/references/images.md).

1. Resolve the repository's default branch SHA with `gh api`.
2. Reuse `refs/heads/copilot-demo-evidence`, or create it from the default branch when absent.
3. Base64-encode the PNG and upload it with the Contents API to a unique path such as
   `docs/issue-evidence/20260824T120000Z-cart.png` on that branch.
4. Use this Markdown URL in the issue body:
   `https://github.com/{owner}/{repo}/raw/copilot-demo-evidence/{path}`.
5. Confirm the image renders for an authenticated repository member.

Never use `raw.githubusercontent.com` for private-repository evidence, never make a public gist,
and never commit evidence to `demo-coworkers` or the bugfix branch.
