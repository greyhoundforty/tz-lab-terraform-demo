# Common tags on PowerVS and VPC resources

## Summary

Apply a shared tag map (lab name + seat prefix) to major VPC and PowerVS resources so instructors can find a seat’s stack in the IBM Cloud console.

## Acceptance criteria

- [ ] A `local.common_tags` (or equivalent) map includes at least `lab = "LAB-1952"` and `prefix = var.prefix`
- [ ] Tags are set on the VPC, Ubuntu VSI, PowerVS workspace, and AIX instance where the provider supports tags
- [ ] No secrets or API keys appear in tag values
- [ ] `terraform fmt -check -recursive lab/terraform` passes

## Out of scope

- Tagging every subnet/route/SG rule
- Cost-center / billing tag schemes beyond the two keys above
- Changing resource names or prefixes

## Test plan

- `terraform fmt -check -recursive lab/terraform`
- `terraform validate` in `lab/terraform/` after init (when providers are available)
- Plan review: tagged resources show the new tags
