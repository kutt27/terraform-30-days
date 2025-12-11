resource "aws_iam_group" "education" {
  name = "Education"
  path = "/groups/"
}

resource "aws_iam_group" "managers" {
  name = "Managers"
  path = "/groups/"
}

resource "aws_iam_group" "engineers" {
  name = "Engineers"
  path = "/groups/"
}

# Add users to the Education group
resource "aws_iam_group_membership" "education_members" {
  name  = "education-group-membership"
  group = aws_iam_group.education.name
  users = [
    for user in aws_iam_user.users : user.name if user.tags.Department == "Education"
  ]
}

# Add users to the Managers group
resource "aws_iam_group_membership" "managers_members" {
  name  = "managers-group-membership"
  group = aws_iam_group.managers.name
  users = [
    for user in aws_iam_user.users : user.name if contains(keys(user.tags), "JobTitle") && can(regex("Manager|CEO", user.tags.JobTitle))
  ]
}

# Add users to the Engineers group
resource "aws_iam_group_membership" "engineers_members" {
  name  = "engineers-group-membership"
  group = aws_iam_group.engineers.name
  users = [
    for user in aws_iam_user.users : user.name if user.tags.Department == "Engineering"
  ]
}

# Define your test policy
resource "aws_iam_policy" "mfa_required_policy" {
  name        = "mfa-required-policy"
  path        = "/"
  description = "Require MFA for all actions except MFA setup"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyAllExceptMFA"
        Effect    = "Deny"
        Action    = "*"
        Resource  = "*"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      },
      {
        Sid    = "AllowMFASetup"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ResyncMFADevice",
          "iam:DeactivateMFADevice",
          "iam:DeleteVirtualMFADevice"
        ]
        Resource = "*"
      }
    ]
  })
}


# Attach test_policy to each group
resource "aws_iam_group_policy_attachment" "education_policy_attach" {
  group      = aws_iam_group.education.name
  policy_arn = aws_iam_policy.mfa_required_policy.arn
}

resource "aws_iam_group_policy_attachment" "managers_policy_attach" {
  group      = aws_iam_group.managers.name
  policy_arn = aws_iam_policy.mfa_required_policy.arn
}

resource "aws_iam_group_policy_attachment" "engineers_policy_attach" {
  group      = aws_iam_group.engineers.name
  policy_arn = aws_iam_policy.mfa_required_policy.arn
}
