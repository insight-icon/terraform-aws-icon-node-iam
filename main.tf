data "aws_caller_identity" "this" {}
data "aws_region" "current" {}

terraform {
  required_version = ">= 0.12"
}

locals {
  name = var.name
  common_tags = {
    "Terraform" = true
    "Environment" = var.environment
  }

  tags = merge(var.tags, local.common_tags)
}

resource "aws_iam_instance_profile" "this" {
  name = "${title(local.name)}InstanceProfile"
  role = aws_iam_role.this.name
}

data "template_file" "ebs_mount_policy" {
  template = file("${path.module}/policies/ebs_mount_policy.json")
  //TODO: IAM lockdown
  vars = {}
}

resource "aws_iam_policy" "ebs_mount_policy" {
  name = "${title(local.name)}EBSPolicy"
  policy = data.template_file.ebs_mount_policy.rendered
}

resource "aws_iam_role_policy_attachment" "efs_mount_policy" {
  role = aws_iam_role.this.name
  policy_arn = aws_iam_policy.ebs_mount_policy.arn
}

resource "aws_iam_role_policy_attachment" "ebs_mount_policy" {
  role = aws_iam_role.this.name
  policy_arn = aws_iam_policy.ebs_mount_policy.arn
}

resource "aws_iam_role" "this" {
  name = title(local.name)
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = local.tags
}
