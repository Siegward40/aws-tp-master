variable "aws_region" {
    type = string
    default = "us-east-1"
}


variable "my_ip" {
    description = "Ip d'acces"
    type = string
    default = "0.0.0.0/0"
}


variable "ssh_key_name" {
    description = "Pour SSH si besoin"
    type = string
    default = ""
}


variable "app_bucket_name" {
    type = string
    default = "lab-app-private-bucket-123456789"
}


variable "db_username" { 
    type = string 
    default = "appadmin" 
}