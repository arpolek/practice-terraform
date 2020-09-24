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

resource "aws_security_group_rule" "allow-http-inbound" {
    type = "ingress"
    security_group_id = "${module.webserver_cluster.elb_security_group_id}"

    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow-all-outbound" {
    type = "egress"
    security_group_id = "${module.webserver_cluster.elb_security_group_id}"

    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

output "elb_dns" {
  value = "${module.webserver_cluster.elb_dns_name}"
}