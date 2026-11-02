# Remote State and Locking

1. Without a configured remote backend, Terraform stores state locally. If User A and User B check out the same repository, each has a separate state file. Running apply independently can cause conflicting infrastructure changes, duplicate resources, or inconsistent state. Local locking does not coordinate separate state files on different computers.

2. An S3 remote backend gives everyone a shared state file and a single source of truth. Enabling S3 versioning also preserves previous state versions for recovery. However, remote storage alone does not prevent simultaneous Terraform operations; state locking is needed to coordinate them.

3. With DynamoDB locking configured, Terraform acquires a lock for the shared state before applying changes. Another apply against that state must wait or fail to acquire the lock. Terraform normally releases the lock when the operation finishes, preventing concurrent applies from interfering with each other.

4. Current Terraform versions also support native S3 state locking through `use_lockfile = true`, so DynamoDB is no longer necessary for that approach. DynamoDB locking is deprecated.
