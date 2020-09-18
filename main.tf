provider "aws" {
    region = "eu-central-1"
}

data "aws_availability_zones" "available" {
    state = "available"
}

variable "port" {
    description = "web server port"
    default = "8080"
    type = string
}

############## start of single web server config ##############
/*
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

output "public_ip-webserver" {
    value = "${aws_instance.webserver.public_ip}"
}
*/
############## start of cluster of webservers ##############

resource "aws_launch_configuration" "cluster-launch-config" {
    image_id = "ami-0e63910157459607d"
    instance_type = "t2.micro"
    security_groups = ["${var.sec_group_name}"]

    user_data = <<-EOF
                #!/bin/bash
                echo "cluster of web servers, currently responds <web server public ip >"
                nohup busybox httpd -f -p "${var.port}" &
                EOF

    lifecycle {
        create_before_destroy = true
    }
}

variable "sec_group_name" {
    description = "security group of a cluster of web servers"
    default = "terraform-sec-group-cluster"
    type = string
}

resource "aws_autoscaling_group" "webserver-cluster" {
    launch_configuration = aws_launch_configuration.cluster-launch-config.id
    availability_zones = ["${data.aws_availability_zones.available.names}"]

    load_balancers = ["${aws_elb.load-balancer.name}"]
    health_check_type = "ELB"

    min_size = 2
    max_size = 2

    tag {
        key = "Name"
        value = "terraform-asg-webservers-cluster"
        propagate_at_launch = true
    }
}

resource "aws_elb" "load-balancer" {
    name = "load-balancer"
    availability_zones = ["${data.aws_availability_zones.available.names}"]
    security_groups = ["${aws_security_group.sec-group-elb.id}"]
    
    listener {
        lb_port = 80
        lb_protocol = "http"
        instance_port = var.port
        instance_protocol = "http"
    }

    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3
        interval = 30
        target = "HTTP:${var.port}"
    }
}

resource "aws_security_group" "sec-group-elb" {
    name = var.elb_sec_group_name

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

variable "elb_sec_group_name" {
    description = "ELB security group"
    default = "elb-security-group"
    type = string
}

output "ELB_DNS_name" {
    value = "${aws_elb.load-balancer.dns_name}"
}
