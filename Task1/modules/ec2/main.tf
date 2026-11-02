locals {
  instance_tags = {
    for name, instance in var.instances : name => merge(var.tags, {
      Name        = name
      Environment = instance.environment
      Owner       = instance.owner
    })
  }
  all_instances = merge(aws_instance.protected, aws_instance.standard)
}

resource "aws_key_pair" "this" {
  for_each = var.instances

  key_name   = each.value.key_name
  public_key = each.value.public_key
  tags       = local.instance_tags[each.key]
}

resource "aws_security_group" "this" {
  name_prefix = "arise-"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_instance" "protected" {
  for_each = { for name, instance in var.instances : name => instance if instance.protected }

  ami                         = each.value.ami_id
  instance_type               = each.value.instance_type
  subnet_id                   = coalesce(each.value.subnet_id, var.subnet_id)
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = aws_key_pair.this[each.key].key_name
  associate_public_ip_address = false
  disable_api_termination     = each.value.protected

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size
    iops                  = each.value.root_volume_iops
    encrypted             = true
    delete_on_termination = true
    tags                  = local.instance_tags[each.key]
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = local.instance_tags[each.key]
}

resource "aws_instance" "standard" {
  for_each = { for name, instance in var.instances : name => instance if !instance.protected }

  ami                         = each.value.ami_id
  instance_type               = each.value.instance_type
  subnet_id                   = coalesce(each.value.subnet_id, var.subnet_id)
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = aws_key_pair.this[each.key].key_name
  associate_public_ip_address = false
  disable_api_termination     = each.value.protected

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = each.value.root_volume_type
    volume_size           = each.value.root_volume_size
    iops                  = each.value.root_volume_iops
    encrypted             = true
    delete_on_termination = true
    tags                  = local.instance_tags[each.key]
  }

  tags = local.instance_tags[each.key]
}
