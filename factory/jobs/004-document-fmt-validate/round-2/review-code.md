VERDICT: PASS

Reviewed `factory/REPO.md`, `spec.md`, `build.md`, and `git diff main...factory/004-document-fmt-validate`. The branch has two commits (873c6d3, 34bc50d). Both touch only `README.md` (+15 lines). No `.tf` files changed. The context-mode MCP failed to load (native module mismatch), so I used plain shell and file reads instead.

## Acceptance criteria after the round 2 wording fixes
- Placement: step 3 now reads `terraform init`, then the new fenced `bash` block, then `terraform plan -out default.tfplan`. The block runs `terraform fmt -check -recursive` and `terraform validate` from `~/tz-lab-terraform-demo/lab/terraform`. Met.
- Split/reorder: the original init/plan block is split. No existing command is removed or reworded. Met.
- Explanation: three short sentences follow the block. They cover:
  - `fmt -check` only lists unformatted files, with exit 0 when clean and non-zero otherwise.
  - Running `terraform fmt` without `-check` rewrites them.
  - `validate` needs `init` first and checks syntax and the provider schema without calling IBM Cloud or needing `IC_API_KEY`.

  The old ambiguous first sentence is fixed. Met.
- Expected result: a separate paragraph says `fmt -check` prints nothing and `validate` prints `Success! The configuration is valid.` Met.
- The added "If either check fails, fix what it names before you plan." line is accurate and adds no new commands or variables.
- Style: plain short sentences, no emoji, `bash` fences, identifiers in backticks. Met.
- No secrets, seat values, or new variables. Met.
- Scope: the diff is README-only. Out-of-scope items (CI, linters, other README sections) are untouched. Met.

## Caveat
- Exit 3 from `terraform fmt -check -recursive lab/terraform` comes only from the local, gitignored `lab/terraform/terraform.tfvars`.
- The tracked `.tf` files are unchanged and clean.
- Round 1 confirmed the README's own heredoc output passes fmt.
- This is not a branch defect, and the README's "prints nothing" claim holds for a student who follows the steps.

## Notes (non-blocking)
- The working tree has unrelated untracked or deleted files (`lab/lab-1952.html`, `lab/corrected-lab-1952.html`, `.bob/`). They are not part of the branch diff.
- The repeated `cd` in the new block is harmless and copy-paste safe.
