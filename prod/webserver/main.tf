provider "aws" {
  region = "eu-central-1"
}

module "webserver_cluster" {
  source = "../../modules/webserver-cluster"
  cluster_name = "webserver-cluster-production"
  launch_configuration_name = "sandbox"
  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
}

resource "aws_autoscaling_schedule" "scale_business_hours" {
  scheduled_action_name = "scale-business-hours"
  min_size              = 2
  max_size              = 3
  desired_capacity      = 2
  recurrence            = "0 9 * * *"

  autoscaling_group_name = "${module.webserver_cluster.asg_name}"
}

resource "aws_autoscaling_schedule" "scale_at_night" {
  scheduled_action_name = "scale-night"
  min_size              = 2
  max_size              = 3
  desired_capacity      = 2
  recurrence            = "0 9 * * *"

  autoscaling_group_name = "${module.webserver_cluster.asg_name}"

}

output "elb_dns" {
  value = "${module.webserver_cluster.elb_dns_name}"
}