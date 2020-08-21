provider "aws" {
  region = "us-east-1"
}

module "admin-server" {
  source = "./modules/admin"
}

module "web-server" {
  source = "./modules/webserver"
  admin-security-group-id = module.admin-server.admin-security-group-id
}

module "worker-server" {
  source = "./modules/worker"
}

output "webserver-domain" {
  value = module.web-server.webserver-dns
}

output "admin-host-public-name" {
  value = module.admin-server.bastion_host_public_name
}
