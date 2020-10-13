provider "aws" {
  region = "eu-central-1"
}

module "webserver_cluster" {
  source = "../../modules/webserver-single"
  single_webserver_name = "single-webserver-staging"
}

/*
that's a commented area
*/
