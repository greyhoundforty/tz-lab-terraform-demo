VERDICT: PASS

All three round-1 UX fixes are applied in `README.md` step 3. The diff against `main` touches only `README.md`, with 15 lines added.

## Round-1 fixes

1. **First sentence fixed.** The old ambiguous sentence is gone. The explanation is now three short sentences, which fits the spec's cap:
   - `fmt -check` only lists unformatted files, and exits 0 when clean and non-zero when not.
   - Run `terraform fmt` without `-check` to rewrite them.
   - `validate` needs `init` first, and checks syntax and the provider schema without calling IBM Cloud or needing `IC_API_KEY`.
2. **Expected output stands alone.** It is its own paragraph, and the first line reads "Expect no output from `fmt -check`, and `Success! The configuration is valid.` from `validate`."
3. **Failure guidance added.** The same paragraph ends with "If either check fails, fix what it names before you plan." It covers `validate` as well as `fmt`.

## Spec checks

- **Order:** init, then the fmt/validate block, then plan. `terraform plan -out default.tfplan` is now in its own block after the explanation, and no existing command was reworded.
- **Style:** short plain sentences, no emoji, commands in fenced `bash` blocks, identifiers in backticks.
- **Scope:** no secrets, seat values, new variables, or `.tf` changes.
- **Repeated `cd`:** the fmt/validate block repeats `cd ~/tz-lab-terraform-demo/lab/terraform`. That keeps the block copy-paste safe, as noted in round 1.

## Non-blocking

- "Check the code before you plan:" is a clear lead-in.
- The bare `terraform fmt -check -recursive lab/terraform` exits 3 in the build working copy because of a gitignored local `terraform.tfvars`. build.md discloses this and the README is unaffected.
- The earlier note still applies: don't tell students to rerun the check after step 4 without warning that a hand-edited `terraform.tfvars` can fail `fmt -check`. It is out of scope here.
- The context-mode tool failed with a Node version mismatch (`better-sqlite3`), so I read the files and diff with plain shell commands instead.
