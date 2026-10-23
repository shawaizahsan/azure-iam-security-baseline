# Azure Key Vault RBAC Lab

## Goal
Use a managed identity to read a Key Vault secret with least-privilege access.

## Completed configuration
- Key Vault: `kv-iambase-6tib4kdqrongo`
- Resource group: `rg-iam-security-baseline`
- Workload identity: `id-iam-baseline-workload`
- Workload role: `Key Vault Secrets User`
- Role scope: the Key Vault resource
- Test secret name: `AppDemoSecret`

## Security outcome
The workload can read secrets but cannot create, change, delete, or manage access to them. Temporary elevated administrator access was removed after setup.

## Key principle
Least privilege: grant each identity only the permissions it needs.
