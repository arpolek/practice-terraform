variable "cluster_name" {
    description = "webserver cluster name"
}

variable "instance_type" {
    description = "instance type e.g. t2.micro"
}

variable "min_size" {
    description = "min size of a cluster"
}

variable "max_size" {
    description = "max size of a cluster"
}

variable "launch_configuration_name" {
    description = "name of a launch configuration"
}