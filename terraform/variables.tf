variable "aws_region" {
type = string
default = "us-east-1"
}


variable "my_ip" {
description = "Votre IP publique (CIDR) pour HTTP/SSH, exemple: 1.2.3.4/32"
type = string
default = "0.0.0.0/0" # **remplacez** par votre IP en pratique
}


variable "ssh_key_name" {
description = "nom de la keypair AWS existante pour SSH si besoin"
type = string
default = ""
}


variable "app_bucket_name" {
type = string
default = "lab-app-private-bucket-123456789"
}


variable "db_username" { type = string default = "appadmin" }