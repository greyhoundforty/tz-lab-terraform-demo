# Build

## Branch
factory/004-document-fmt-validate

Commits: 873c6d3 (round 1), 34bc50d (round 2). Both touch `README.md` only.

## What changed
- `README.md` step 3: split the `terraform init` / `terraform plan -out default.tfplan` block so the order is init -> fmt/validate -> plan.
- Added a `bash` block (from `~/tz-lab-terraform-demo/lab/terraform`) running `terraform fmt -check -recursive` and `terraform validate`.
- Added a three-sentence explanation: `fmt -check` lists unformatted files and exits 0 when clean, `terraform fmt` rewrites them, and `validate` needs `init` first and does not call IBM Cloud or need `IC_API_KEY`.
- No `.tf` files, variables, or existing commands changed.

### Round 2 (review-ux CHANGES)
- Rewrote the ambiguous first sentence ("a non-zero exit lists the files, which `terraform fmt` ... rewrites"). It is now three short sentences: what `fmt -check` does and its exit codes; run `terraform fmt` without `-check` to rewrite; what `validate` needs and checks.
- Moved the expected output into its own short paragraph: no output from `fmt -check`, and `Success! The configuration is valid.` from `validate`.
- Added "If either check fails, fix what it names before you plan." to the expected-output paragraph.
- Kept the repeated `cd` in the block (reviewers: harmless, copy-paste safe).

## Tests run
- `terraform fmt -check -recursive lab/terraform` (repo root) → exit 3, only because of the local, gitignored `lab/terraform/terraform.tfvars` (seat values, untracked, untouched). Same as round 1; reviewers confirmed the README's own step 3 tfvars passes.
- `terraform fmt -check lab/terraform/*.tf` → exit 0 (tracked `.tf` files clean; none changed).
- `cd lab/terraform && terraform validate` (already initialised with `-backend=false`) → `Success! The configuration is valid.`
- `git show --stat HEAD` → only `README.md` changed.

## Spec checklist
- [x] Step 3 has a new fenced `bash` block after `terraform init` and before `terraform plan -out default.tfplan`, running `terraform fmt -check -recursive` and `terraform validate` from `~/tz-lab-terraform-demo/lab/terraform`.
- [x] init / plan block split so the sequence is init -> fmt/validate -> plan; no commands removed or reworded.
- [x] Explanation (three sentences) covers `fmt -check` exit codes, `terraform fmt` rewriting, and `validate` needing `init` and not calling IBM Cloud / needing `IC_API_KEY`.
- [x] Expected result stated: `fmt -check` prints nothing; `validate` prints `Success! The configuration is valid.`
- [x] Wording matches README style (plain short sentences, no emoji, `bash` blocks, backticked identifiers).
- [x] No secrets, seat-specific values, or new variables.
- [~] `terraform fmt -check -recursive lab/terraform` exits 0: true for all tracked `.tf` files; the recursive command exits 3 in this working copy only because of the pre-existing gitignored local `terraform.tfvars`. No `.tf` changes made.
