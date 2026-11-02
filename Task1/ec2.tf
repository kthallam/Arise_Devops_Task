module "ec2" {
  source = "./modules/ec2"

  instances = var.instances
  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id
  tags      = var.tags
}
