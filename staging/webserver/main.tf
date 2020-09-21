provider "aws" {
  region = "eu-central-1"
}

module "webserver_cluster" {
  source = "../../modules/webserver-single"
}