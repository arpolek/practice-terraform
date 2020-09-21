variable "port" {
    description = "web server port"
    default = "8080"
    type = string
}

resource "aws_security_group" "security_group" {
    name = "terraform-security-group-4"

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

output "public_ip-webserver" {
    value = "${aws_instance.webserver.public_ip}"
}
