VERDICT: PASS

Scope: docs-only change (`README.md`, +13 lines). No UI to review; judged formatting and readability.

- Order in step 3 reads init -> fmt/validate -> plan, as the spec requires. Fenced `bash` blocks are used consistently, each closed properly.
- The lead-in line ("Check the code before you plan:") is short and plain, matching the README's tone. No emoji.
- The explanation paragraph is dense: three sentences in one block, with a long first sentence. It is within the spec's one-to-three sentence limit, so it is not blocking. Optional follow-up: split the expected-output sentence into its own line.
- Identifiers and commands are in backticks.
- The repeated `cd ~/tz-lab-terraform-demo/lab/terraform` line in the new block is redundant after the earlier `cd`. It is harmless, and it makes the block copy-paste safe on its own.
- The `plan` block is now separated from `init` by prose. This is the intended structure and is readable.

Nothing UI-related to block.
