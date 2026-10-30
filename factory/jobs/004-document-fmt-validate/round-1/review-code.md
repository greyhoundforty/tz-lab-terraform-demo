VERDICT: PASS

Reviewed `git diff main...factory/004-document-fmt-validate` against spec.md, build.md, and factory/REPO.md.

## Acceptance criteria
- Placement: new fenced `bash` block in step 3 sits after `terraform init` and before `terraform plan -out default.tfplan`. It runs `terraform fmt -check -recursive` and `terraform validate` from `~/tz-lab-terraform-demo/lab/terraform`. Met.
- Split/reorder: the init/plan block is split into init, then fmt/validate, then plan. No existing commands removed or reworded. Met.
- Explanation: three sentences. They cover `fmt -check` exit 0 vs non-zero listing files, `terraform fmt` without `-check` rewriting, and `validate` needing `init` and not calling IBM Cloud or needing `IC_API_KEY`. Met.
- Expected output: `fmt -check` prints nothing, and `validate` prints `Success! The configuration is valid.` Met.
- Style: plain short sentences, no emoji, `bash` fence, identifiers in backticks. Met.
- No secrets, seat values, or new variables. Met.
- Scope: `git diff --stat` shows only `README.md` (+13). No `.tf` changes. Met.

## fmt -check -recursive caveat
- Reproduced exit 3 in the working copy. The only file flagged is the local, gitignored `lab/terraform/terraform.tfvars`, so it is not a README or tracked-file problem.
- I ran the README's own step 3 heredoc output (`terraform.tfvars`) through `terraform fmt -check -recursive` in a temp dir. It exited 0 with no output. A student who follows the README gets the "prints nothing" result the README promises, so the doc is accurate.

## REPO.md conventions
- The README stays accurate for the lab steps.
- Nothing is added that conflicts with the seat-prefix or no-secrets rules.

## Non-blocking nits (no action required)
- The first explanation sentence is long. It is still readable and within the three-sentence limit.
