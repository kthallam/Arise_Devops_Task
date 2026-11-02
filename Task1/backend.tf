terraform {
  backend "s3" {
    # Placeholder: replace with your existing, versioned state bucket.
    bucket = "terraform-state-bucket"
    key    = "module_ec2/terraform.tfstate"
    region = "us-east-1"

    encrypt      = true
    use_lockfile = true
  }
}
