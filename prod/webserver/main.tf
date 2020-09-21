provider "aws" {
  region = "eu-central-1"
}

module "webserver_cluster" {
  source = "../../modules/webserver-cluster"
  cluster_name = "webserver-cluster-production"
  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
}
