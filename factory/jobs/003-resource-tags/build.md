# Build

## Branch

factory/003-resource-tags

## What changed

- Added `local.common_tags` with `lab` and `prefix` in `names.tf`
- Applied tags to VPC, Ubuntu VSI, PowerVS workspace, and AIX instance
- Left subnets and SG rules untagged (out of scope)

## Tests run

- `terraform fmt -check -recursive lab/terraform` → ok

## Spec checklist

- [x] Shared tag map with lab + prefix
- [x] Tags on VPC, VSI, workspace, AIX
- [x] No secrets in tag values
- [x] fmt check

## Round 2 notes

Addressing security CHANGES from round 1 (do not put resource group id or CRNs into tags). UI review for round 2 still pending.
