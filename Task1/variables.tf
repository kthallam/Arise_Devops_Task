variable "instances" {
  description = "EC2 instance settings, keyed by instance name."
  type = map(object({
    ami_id           = string
    instance_type    = string
    root_volume_type = string
    root_volume_size = number
    root_volume_iops = optional(number)
    key_name         = string
    public_key       = string
    environment      = string
    owner            = string
    protected        = optional(bool, false)
  }))

}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
