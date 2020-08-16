provider "aws" {
  region = "us-east-1"
}

module "admin-server" {
  source = "./modules/admin"
}

module "web-server" {
  source = "./modules/webserver"
}

module "worker-server" {
  source = "./modules/worker"
}

output "webserver-domain" {
  value = module.web-server.webserver-dns
}
