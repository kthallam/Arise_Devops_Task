# Task 4 — CI policy

## What is allowed, and why

- ECR authentication uses `ecr:GetAuthorizationToken` on `*` because that API does not support repository-level resources. Authentication alone does not grant access to other repositories.
- Layer checks, multipart layer upload, and PutImage are limited to the one repository. `ecr:BatchGetImage` is included because AWS's documented Docker push permission set includes it; clients can query manifests as part of a push. This is not blanket ECR read access.
- `ecs:RegisterTaskDefinition` is scoped to `arn:aws:ecs:us-east-1:000000000000:task-definition/task4-app:*` and the chosen region. The current AWS service authorization reference lists task-definition resource support for this action.
- `ecs:UpdateService` is scoped to the exact service ARN and cluster, and requires a supplied task definition from the approved family. It cannot deploy to another service or select a different family. The family revision wildcard is needed because each deployment registers a new revision.
- `iam:PassRole` is limited to the exact execution and task roles, and only to `ecs-tasks.amazonaws.com`. This is needed when registering a definition that names those roles; it does not allow changing the roles or assuming them directly.
- `s3:ListBucket` covers listing the artifacts bucket; `s3:GetObject` covers reading its objects. Bucket and object ARNs are separate because the actions authorize different resource types.

## Deliberately left out

No managed policies, `ecr:*`, `ecs:*`, `s3:*`, IAM administration, `sts:AssumeRole`, or access to any role  is granted to CI. There are no permissions to create repositories, clusters, services, roles, or buckets; change repository/bucket policies; delete images or task definitions; run standalone ECS tasks; execute commands in containers; write/delete artifacts; read secrets; or decrypt arbitrary KMS keys.



```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AuthToECR",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Sid": "PushRepository",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
        "ecr:BatchGetImage"
      ],
      "Resource": "arn:aws:ecr:us-east-1:000000000000:repository/task4-app"
    },
    {
      "Sid": "RegisterNewTaskDefinition",
      "Effect": "Allow",
      "Action": "ecs:RegisterTaskDefinition",
      "Resource": "arn:aws:ecs:us-east-1:000000000000:task-definition/task4-app:*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    },
    {
      "Sid": "Deploy",
      "Effect": "Allow",
      "Action": "ecs:UpdateService",
      "Resource": "arn:aws:ecs:us-east-1:000000000000:service/task4-cluster/task4-service",
      "Condition": {
        "ArnEquals": {
          "ecs:cluster": "arn:aws:ecs:us-east-1:000000000000:cluster/task4-cluster"
        },
        "ArnLike": {
          "ecs:task-definition": "arn:aws:ecs:us-east-1:000000000000:task-definition/task4-app:*"
        }
      }
    },
    {
      "Sid": "PassRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": [
        "arn:aws:iam::000000000000:role/task4-execution-role",
        "arn:aws:iam::000000000000:role/task4-task-role"
      ],
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "ecs-tasks.amazonaws.com"
        }
      }
    },
    {
      "Sid": "ListBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::task4-build-artifacts-000000000000"
    },
    {
      "Sid": "ReadBuildArtifacts",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::task4-build-artifacts-000000000000/*"
    }
  ]
}
```