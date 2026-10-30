VERDICT: PASS

Scope reviewed: `git diff main...factory/004-document-fmt-validate` (`README.md` only, +15 lines), against spec.md, build.md, and the round-1 reviews.

Findings:
- Secrets: none. The diff adds no API keys, tokens, tfvars values, or seat-specific data. The text says `validate` does not need `IC_API_KEY`, which is accurate. It does not encourage exposing credentials.
- Commands: the only new commands are `cd`, `terraform fmt -check -recursive`, and `terraform validate`. All are local, and `fmt -check` is read-only. There is no `curl | sh`, `sudo`, eval, or downloaded script.
- Network and exposure: no new URLs, endpoints, CIDR, security group, or public-exposure changes. No `.tf` files changed.
- Dependencies: nothing new. It uses only the Terraform CLI the README already uses.
- Round 2 changes: the diff since round 1 only rewrites prose (sentence split, a separate expected-output paragraph, and a "fix what it names before you plan" line). It adds no new security surface.
- Pre-existing, out of scope: `terraform plan -out default.tfplan` can write sensitive values to a plan file. The line is unchanged by this job.

No fixes required.
