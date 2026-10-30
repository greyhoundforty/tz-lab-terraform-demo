VERDICT: CHANGES

Scope is correct: README-only, 13 lines added, order is init -> fmt/validate -> plan, no commands reworded, no secrets. The problem is the explanation paragraph (README line ~94). It is one dense block, and the first sentence is hard for a student to parse.

## Required changes

1. **Fix the first sentence.** "a non-zero exit lists the files, which `terraform fmt` without `-check` rewrites" is ambiguous. A student can read it as "the exit code lists files" or "the files rewrite themselves." Split it into short, plain sentences. Keep it within the spec's 3-sentence cap, and drop the "only reports" phrasing if needed. Suggested text:

   > `terraform fmt -check` prints the names of any unformatted files and exits non-zero. It changes nothing. To fix them, run `terraform fmt`. `terraform validate` needs `terraform init` first. It checks syntax and the provider schema, and does not call IBM Cloud or need `IC_API_KEY`.

   If that exceeds three sentences, merge the last two; the spec wording allows it.

2. **Put the expected output in its own short line or sentence.** Right now "Expect `fmt -check` to print nothing and `terraform validate` to print `Success! The configuration is valid.`" is buried at the end of a long paragraph. Students scan for it, so it should stand apart, for example as a separate paragraph or the lead sentence ("Expect no output from `fmt -check`, and `Success! The configuration is valid.` from `validate`.").

3. **Say what to do if a check fails.** The text covers `fmt` but not `validate`. Add one short clause: "If `validate` fails, fix the error it names before you plan." Students in a timed lab need to know the plan step should not run on a failing check. If there is no room under the 3-sentence cap, this clause takes priority over restating what `fmt` without `-check` does.

## Non-blocking notes

- The repeated `cd ~/tz-lab-terraform-demo/lab/terraform` in the new block is harmless and makes the block copy-paste safe. Keep it.
- `terraform fmt -check -recursive` on a student's `terraform.tfvars` passes at this point (I checked the exact heredoc from step 3). It will flag the file after step 4 if a student edits `aix_image_name` by hand without keeping the `=` aligned. That is outside this job's scope, but do not tell students to rerun the check after step 4 without mentioning it.
- build.md notes `fmt -check -recursive lab/terraform` exits 3 locally because of a gitignored `terraform.tfvars`. That is accurate, and the repo's tracked `.tf` files are clean. Nothing to change in the README.
