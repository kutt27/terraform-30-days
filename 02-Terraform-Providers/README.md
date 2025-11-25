## Terraform Provider

#### Topic Covered:
- Terraform Providers
- Provider version vs Terraform core version
- Why version matters
- Version constraints
- Operators for versions

Blog: https://amals27.hashnode.dev/terraform-providers

Code: [Code](Code/main.tf)

**Steps**:

```bash
cd Code
terraform init
terraform plan
# this will create .terraform folder
# this will download the provider and create .terraform.lock.hcl file
# this will create the state file after plan phase
```
The executables are deleted before pushing to github.

#### Prerequisite:

1. Install aws cli and terraform.
2. Configure aws cli with your aws account. `aws configure`
3. Go to aws console create a new IAM user with the permission based on code. Here, access to vpc is required. Here, we are planning, so no issues.

