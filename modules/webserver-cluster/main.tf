data "aws_availability_zones" "available" {
    state = "available"
}

variable "port" {
    description = "web server port"
    default = "8080"
    type = string
}

resource "aws_security_group" "security_group" {
    name = "${var.cluster_name}-terraform-security-group-4"

    ingress {
        from_port = var.port
        to_port = var.port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_launch_configuration" "launch-configuration" {
    image_id = "ami-0e63910157459607d"
    name = "${var.launch_configuration_name}-launch-configuration"
    instance_type = "${var.instance_type}"
    security_groups = ["${aws_security_group.security_group.id}"]

    user_data = <<-EOF
                #!/bin/bash
                echo "web server" > index.html
                nohup busybox httpd -f -p "${var.port}" &
                EOF

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "autoscaling-group" {
    launch_configuration = aws_launch_configuration.launch-configuration.id
    availability_zones = data.aws_availability_zones.available.names

    load_balancers = ["${aws_elb.elb.name}"]
    health_check_type = "ELB"

    min_size = "${var.min_size}"
    max_size = "${var.max_size}"

    tag {
        key = "Name"
        value = "${var.cluster_name}-terraform-asg"
        propagate_at_launch = true
    }
}

resource "aws_elb" "elb" {
    name = "${var.cluster_name}-asg"
    availability_zones = data.aws_availability_zones.available.names
    security_groups = ["${aws_security_group.security-group-elb.id}"]

    listener {
        lb_port = 80
        lb_protocol = "HTTP"
        instance_port = var.port
        instance_protocol = "HTTP"
    }

    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3
        interval = 30
        target = "HTTP:${var.port}/"
    }
}

resource "aws_security_group" "security-group-elb" {
    name = "${var.cluster_name}-security-group-elb"

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

output "elb_dns_name" {
    value = "${aws_elb.elb.dns_name}"
}

output "asg_name" {
    value = "${aws_autoscaling_group.autoscaling-group.name}"
}