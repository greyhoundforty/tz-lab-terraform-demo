# Document `terraform fmt` / `validate` in the README setup

## Summary
The README walks students through `terraform init` and `terraform plan` but never mentions `terraform fmt` or `terraform validate`, which are the repo's own test commands (see `factory/REPO.md`). Add a short, accurate checks block to the Terraform setup flow in `README.md` (step 3, directly after `terraform init`, before the first `terraform plan`) so students can confirm the code is formatted and valid before planning. README-only change; no `.tf` files change.

## Acceptance criteria
- [ ] `README.md` step 3 ("First apply") contains a new fenced `bash` block, placed after `terraform init` and before `terraform plan -out default.tfplan`, that runs `terraform fmt -check -recursive` and `terraform validate` from `~/tz-lab-terraform-demo/lab/terraform`.
- [ ] The existing `terraform init` / `terraform plan -out default.tfplan` block is split or reordered so the sequence reads init -> fmt/validate -> plan. No existing commands are removed or reworded beyond that.
- [ ] A one- to three-sentence explanation follows the block and states: `fmt -check` only reports unformatted files (exit code 0 means clean, non-zero lists the files), `terraform fmt` without `-check` rewrites them, and `validate` needs `terraform init` first and checks syntax and provider schema without calling IBM Cloud or needing `IC_API_KEY`.
- [ ] The README states the expected result: `terraform validate` prints `Success! The configuration is valid.` and `fmt -check` prints nothing.
- [ ] Wording matches the README's existing style: plain, short sentences, no emoji, commands in fenced `bash` blocks, identifiers in backticks.
- [ ] No secrets, seat-specific values, or new variables are introduced.
- [ ] `terraform fmt -check -recursive lab/terraform` still exits 0 from the repo root (no `.tf` changes made).

## Out of scope
- Changes to any `lab/terraform/*.tf` files, providers, or variables.
- CI workflows, pre-commit hooks, or Makefiles that run fmt/validate.
- Documenting `tflint`, `checkov`, or other linters.
- Restructuring other README sections (steps 1, 2, 4, 5, new-terminal, after-class).
- Adding a separate "Development" or "Contributing" section.

## Test plan
1. From the repo root, run `terraform fmt -check -recursive lab/terraform`. It must exit 0.
2. Manual README check: open `README.md` and confirm the order in step 3 is `terraform init`, then the fmt/validate block, then `terraform plan -out default.tfplan`, followed by the explanatory text.
3. If provider access is available, run `cd lab/terraform && terraform init && terraform fmt -check -recursive && terraform validate` and confirm the output matches what the README says. If not, state that `validate` was not run.
4. `git diff --stat` should show only `README.md` changed (plus factory job files).
