# Create IAM users
resource "aws_iam_user" "users" {
  for_each = {for user in local.users: "${user.first_name} ${user.last_name}" => user} # this is a map
  name = lower("${substr(each.value.first_name, 0, 1)}${each.value.last_name}")
  path = "/users/"
  tags = {
    "DisplayName" = "${each.value.first_name} ${each.value.last_name}"
    "Department"  = each.value.department
    "JobTitle"    = each.value.job_title
    "Email"       = lookup(each.value, "email", "")
    "Phone"       = lookup(each.value, "phone", "")
  }
}

resource "aws_iam_user_login_profile" "users" {
  for_each = aws_iam_user.users

  user                    = each.value.name
  password_reset_required = true

  lifecycle {
    ignore_changes = [
      password_length,
      password_reset_required,
    ]
  }
}

output "user_passwords" {
  value = {
    for user, profile in aws_iam_user_login_profile.users :
    user => "Password created - user must reset on first login"
  }
  sensitive = true
}


