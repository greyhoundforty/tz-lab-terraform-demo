VERDICT: PASS

Scope reviewed: `git diff main...factory/004-document-fmt-validate` (README.md only, +13 lines).

Findings:
- Secrets: none. No API keys, tokens, tfvars values, or seat-specific data added. The text says `validate` does not need `IC_API_KEY`, which is accurate and encourages no credential exposure.
- Subprocess/injection: the only new commands are `cd`, `terraform fmt -check -recursive`, and `terraform validate`. No `curl | sh`, `sudo`, eval, or downloaded scripts. `fmt -check` is read-only.
- Network/exposure: no new URLs, endpoints, or security group, CIDR, or public-exposure changes. No `.tf` files touched.
- Dependency risk: none introduced. Only the Terraform CLI the README already uses.
- State/data: no backend or state guidance changed. The `terraform plan -out default.tfplan` line is unchanged, and the `.tfplan` file contains values that may be sensitive. This is pre-existing and out of scope.

No fixes required.
