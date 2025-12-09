




## Pending

7. CI/CD Pipeline for Automatic Deployments

Write a pipeline for deploying the website automatically when changes are pushed to the repository.

The most common CI/CD tool for this setup is AWS CodePipeline orchestrated with CodeBuild (triggered by changes in your Git repository, e.g., GitHub, CodeCommit).

IAM Roles

You will need an IAM role for CodePipeline.

CodePipeline Structure

The pipeline will generally have three stages:

Source Stage: Triggers on a Git push.

Build Stage (CodeBuild):

Runs terraform init and terraform apply.

Self-Correction: If your website files (www/) change, you don't need a terraform apply. The aws_s3_object resource is already used filemd5 for change detection. If the file content changes, Terraform will update the S3 object on the next apply.

Deploy Stage (CloudFront Invalidation): Triggers a command to invalidate the CloudFront cache, ensuring visitors see the new files immediately.

The best way to handle this in Terraform is to use the dedicated aws_codepipeline and aws_codebuild resources.

# Example CodeBuild Project (for S3 Sync and Invalidation)
resource "aws_codebuild_project" "build_project" {
  # ... configure CodeBuild service role, environment, and source (e.g., GitHub/CodeCommit)

  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

  source {
    type            = "GITHUB" # Or CODECOMMIT
    location        = "your-repo/your-site" # Update this
    git_clone_depth = 1
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    environment_variables {
      name  = "CLOUDFRONT_ID"
      value = aws_cloudfront_distribution.s3_distribution.id
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
}

Once all these resources are defined, running terraform apply will set up the entire infrastructure, including the pipeline and all advanced CloudFront settings.