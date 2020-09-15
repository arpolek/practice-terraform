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
        nohup busybox httpd -f -p 8080 &
        EOF
    
    tags = {
        Name = "terraform-webserver"
    }
}

resource "aws_security_group" "security_group" {
    name = var.security_group_name

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

variable "security_group_name" {
    description = "terraform-security-group-4"
    type = string
    default = "terraform-security-group-4"
}
