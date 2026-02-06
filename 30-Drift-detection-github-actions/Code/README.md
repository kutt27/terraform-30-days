## Configuration

Run 
```sh
bash scripts/setup-backend.sh <bucket-name> <region>

```

Example:
```sh
bash scripts/setup-backend.sh day-30-terraform-amals-practice us-east-1
```

Output:
```
==========================================
Terraform Backend Setup (Multi-Environment)
==========================================
Base Name: day30-drift-detection-amals
Region:    us-east-1
Envs:      dev prod
==========================================

--- Setting up environment: dev ---
Bucket: day30-drift-detection-amals-dev
Creating S3 bucket...
{
    "Location": "/day30-drift-detection-amals-dev",
    "BucketArn": "arn:aws:s3:::day30-drift-detection-amals-dev"
}
✅ Bucket created.
Enabling versioning...
Enabling encryption...
Blocking public access...

--- Setting up environment: prod ---
Bucket: day30-drift-detection-amals-prod
Creating S3 bucket...
{
    "Location": "/day30-drift-detection-amals-prod",
    "BucketArn": "arn:aws:s3:::day30-drift-detection-amals-prod"
}
✅ Bucket created.
Enabling versioning...
Enabling encryption...
Blocking public access...

==========================================
✅ All Backend setups complete!
==========================================

Next Steps:
1. Verify these names match your .hcl files:
   - backend-dev.hcl:  day30-drift-detection-amals-dev
   - backend-prod.hcl: day30-drift-detection-amals-prod

2. Add AWS Credentials to GitHub Secrets.
3. Create 'dev' and 'prod' Environments in GitHub Settings.
==========================================
```

Deploy via CI/CD

