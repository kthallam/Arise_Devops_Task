# Task 5 — Fix roleB assuming roleC across accounts

## Why the original failed

The trust policy names `arn:aws:iam::000000000000:user/roleB`. The `user/`
part identifies an IAM user, not an IAM role. A user and a role with the same
name are different identities. To trust the intended role, the principal must
be its IAM role ARN, such as `arn:aws:iam::000000000000:role/roleB`.


If the named IAM user does not exist, IAM can reject the trust policy with an
invalid-principal error.

Cross-account access needs permission on both sides. Account B's roleC trust
policy must accept roleB, and Account A's roleB must have an identity policy
allowing `sts:AssumeRole` on roleC's ARN. The snippet only shows the trust side;
if the caller permission was absent elsewhere, correcting the principal alone
would still leave the request denied. The fix is to add the caller policy explicitly.

The S3 policy is separate: it controls what roleC can do after assumption.
`s3:*` on `*` is valid and does not cause the trust failure. It grants broad
S3 access; narrow it to the required actions and bucket/object ARNs.

## Corrected configuration


```hcl
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

variable "account_a_id" {
  type    = string
  default = "000000000000" # Replace with the real Account A ID.
}

variable "account_b_id" {
  type    = string
  default = "111111111111" # Replace with the real Account B ID.
}

# Configure these AWS profiles with deployment credentials for the two accounts.
provider "aws" {
  alias               = "account_a"
  profile             = "account-a"
  region              = "us-east-1"
  allowed_account_ids = [var.account_a_id]
}

provider "aws" {
  alias               = "account_b"
  profile             = "account-b"
  region              = "us-east-1"
  allowed_account_ids = [var.account_b_id]
}

# roleB already exists in Account A. Its ARN includes any IAM path.
data "aws_iam_role" "roleB" {
  provider = aws.account_a
  name     = "roleB"
}

data "aws_iam_policy_document" "roleC_trust" {
  provider = aws.account_b

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.roleB.arn]
    }
  }
}

resource "aws_iam_role" "roleC" {
  provider           = aws.account_b
  name               = "roleC"
  assume_role_policy = data.aws_iam_policy_document.roleC_trust.json
}

# The caller also needs permission to assume the destination role.
resource "aws_iam_role_policy" "roleB_assume_roleC" {
  provider = aws.account_a
  name     = "roleB-assume-roleC"
  role     = data.aws_iam_role.roleB.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.roleC.arn
    }]
  })
}

# Retains the S3 permissions from the supplied snippet.
resource "aws_iam_role_policy" "roleC_s3" {
  provider = aws.account_b
  name     = "roleC-s3-access"
  role     = aws_iam_role.roleC.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:*"
      Resource = "*"
    }]
  })
}

output "roleC_arn" {
  value = aws_iam_role.roleC.arn
}
```


## Setup and verification

Replace the dummy account IDs and configure deployment profiles `account-a`
and `account-b` for their respective accounts. roleB must already exist.
If roleC already exists, import it instead of attempting to create a duplicate.
Run `terraform init`, `terraform validate`, and `terraform plan` from `task5/`.
This directory uses its own local state; it does not inherit the EC2 backend.

After applying, use active roleB session credentials to test the trust:

```sh
aws sts get-caller-identity
aws sts assume-role --role-arn arn:aws:iam::111111111111:role/roleC --role-session-name task5-check
```

Replace the Account B ID. The first command should identify a roleB session.
The second returns temporary roleC credentials; use those credentials for
subsequent calls as roleC. It does not automatically switch the current CLI session.

The two allow policies do not override applicable explicit denies or restrictions
from permissions boundaries, session policies, or organization policies.
If roleB is deleted and recreated, refresh roleC's trust policy: IAM stores the
trusted role's unique principal ID, which changes even if its ARN is reused.

References: [AWS cross-account access](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies-cross-account-resource-access.html),
[AWS Principal documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html).

The standalone Terraform configuration passed `terraform validate`. Live
cross-account assumption has not been tested against AWS.
