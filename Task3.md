## Would you actually give engine and ci IAM users with access keys in a real production setup, or would you do something different? Explain.

I would use IAM roles with temporary credentials instead of IAM users with
long-lived access keys wherever possible.

For ci, I would use the CI platform's OIDC federation to assume a deployment
role. I would restrict its trust policy to the intended repository and branch
or deployment environment. This avoids storing a permanent AWS secret in CI.

For engine, if it is an AWS workload, I would use its native workload role,
such as an EC2 instance profile or ECS task role. For a workload outside AWS,
I would consider workload federation or IAM Roles Anywhere. If engine is a
person, I would use IAM Identity Center with MFA and temporary CLI credentials.

Temporary credentials expire, reducing the exposure from leaked credentials.
I would only use long-lived access keys when the system cannot use these
alternatives, with tightly scoped permissions, secure storage, monitoring,
rotation, and prompt revocation.

## In roleC's trust policy, why does it matter whether you trust the whole Account A root vs. roleB's specific ARN?

Trusting `arn:aws:iam::000000000000:root` delegates trust to Account A. It does
not mean only the root user. Without further restrictions, Account A can
authorize other users or roles to assume roleC by granting them the appropriate
`sts:AssumeRole` permission.

Trusting `arn:aws:iam::000000000000:role/roleB` limits the trusted principal
to roleB and its sessions. Other Account A identities cannot directly assume
roleC merely because they have an identity policy allowing it. roleB still
needs permission to call `sts:AssumeRole` on roleC.

The specific role ARN therefore enforces the intended direct access boundary.
Anyone allowed to assume roleB can still reach roleC through a roleB session,
so roleB's own trust policy must also be controlled.
