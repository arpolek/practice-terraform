############## start of single web server config ##############

provider "aws" {
    region = "eu-central-1"
}

resource "aws_instance" "webserver" {
    ami = "ami-0e63910157459607d"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.security_group.id}"]

    user_data = <<-EOF
                #!/bin/bash
                echo "web server" > index.html
                nohup busybox httpd -f -p "${var.port}" &
                EOF
    
    tags = {
        Name = "terraform-webserver"
    }
}

resource "aws_security_group" "security_group" {
    name = var.security_group_name

    ingress {
        from_port = var.port
        to_port = var.port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

variable "security_group_name" {
    description = "terraform-security-group-4"
    type = string
    default = "terraform-security-group-4"
}

variable "port" {
    description = "web server port"
    default = "8080"
    type = string
}

output "public_ip-webserver" {
    value = "${aws_instance.webserver.public_ip}"
}

############## start of cluster of webservers ##############

resource "aws_launch_configuration" "cluster-launch-config" {
    image_id = "ami-0e63910157459607d"
    instance_type = "t2.micro"
    security_groups = ["${var.sec_group}"]"

    user_data = <<-EOF
                #!/bin/bash
                echo "cluster of web servers, currently responds <web server public ip >"
                nohup busybox httpd -f -p "${var.port}" &
                EOF

    lifecycle {
        create_before_destroy = true
    }
}

variable "sec_group" {
    description = "security group of a cluster of web servers"
    default = "terraform-sec-group-cluster"
    type = string
}

resource "aws_autoscaling_group" "webserver-cluster" {
    launch_configuration = "${var.aws_launch_configuration.cluster-launch_configuration.id}"
    availability_zones = ["${data.aws_availability_zones.all.names}"]

    min_size = 1
    max_size = 2

    tag {
        key = "Name"
        value = "terraform-asg-webservers-cluster"
        propagate_at_launch = true
    }
}

data "aws_availability_zones" "all" {}