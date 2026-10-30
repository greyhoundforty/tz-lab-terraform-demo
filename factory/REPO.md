# Repo context (for factory agents)

Read this before writing a spec, build, or review.

| | |
|---|---|
| **Language** | Terraform (`>= 1.5.0`) with IBM Cloud provider (`IBM-Cloud/ibm`) |
| **Entry** | `lab/terraform/` — PowerVS workspace, VPC, transit gateway, AIX + Ubuntu |
| **Deps** | Terraform CLI; IBM Cloud plugins (`power-iaas`, `vpc-infrastructure`, `tg-cli`) for lab steps |
| **Config** | `IC_API_KEY` env (or `ibmcloud_api_key` var). Seat values in `terraform.tfvars` (gitignored) |
| **Test command** | `terraform fmt -check -recursive lab/terraform`. After `terraform init` in `lab/terraform/`, also `terraform validate` when credentials/providers are available. |
| **Conventions** | Resources under `lab/terraform/*.tf`. Seat-prefixed names via `var.prefix`. No secrets in committed files. Keep README lab steps accurate when behavior changes. |
| **Git** | Feature branches named `factory/<job-id>`. Merge target: `main`. |

## What the lab does

Two applies: first builds VPC + PowerVS workspace + transit gateway; second adds the AIX server once `aix_image_name` is set. Students follow `README.md` from IBM Cloud Shell.
