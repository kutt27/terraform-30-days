 # S3 Security & Operations Monitoring (Mini Project)

Steps:

```bash
cd scripts
./build_layer_docker.sh
cd ../terraform
```

Update the `terraform.tfvars` email, with the respective email.

**Deploy**

```bash
terraform init
terraform plan
terraform apply
```