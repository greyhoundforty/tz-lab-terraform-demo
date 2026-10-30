APPROVE

Rationale:
- Round 2 verdicts are all PASS (code, security, ui, ux). The only round 1 CHANGES (ux) was fixed in round 2 and re-verified.
- The diff `main...factory/004-document-fmt-validate` touches only `README.md` (+15 lines). No `.tf` files, secrets, seat values, or new variables.
- Step 3 now reads init -> fmt/validate -> plan. The explanation, the expected-output paragraph, and the failure guidance match the spec and the README style.
- One caveat, not blocking: `terraform fmt -check -recursive lab/terraform` exits 3 in the build working copy. The cause is the local, gitignored `lab/terraform/terraform.tfvars`, not a tracked file. Tracked `.tf` files are clean and unchanged, and the README's own tfvars heredoc passes `fmt -check`. build.md discloses this.
- `terraform validate` ran and printed `Success! The configuration is valid.`
- No policy risk, flaky tests, or unresolved critical issues.
