#vpc variables

variable "vpc_cidr_block" {
    type    = string
    default = "192.168.0.0/16"
}

variable "pub1_subnet_cidr_block" {

    type = string
    default = "192.168.2.0/24"
}

variable "pub2_subnet_cidr_block" {

    type = string
    default = "192.168.4.0/24"
}

variable "pub3_subnet_cidr_block" {

    type = string
    default = "192.168.6.0/24"
}

variable "prv1_subnet_cidr_block" {

    type = string
    default = "192.168.12.0/24"
}

variable "prv2_subnet_cidr_block" {

    type = string
    default = "192.168.10.0/24"
}
