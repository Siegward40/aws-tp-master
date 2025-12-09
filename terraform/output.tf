output "ec2_public_ip" {
description = "IP publique de l'EC2"
value = aws_instance.web.public_ip
}


output "rds_endpoint" {
description = "Endpoint RDS (endpoint privé)"
value = aws_db_instance.app_db.address
}


output "db_password" {
description = "Mot de passe DB généré (sensible)"
value = random_password.db_pass.result
sensitive = true
}


output "s3_bucket" { value = aws_s3_bucket.app_bucket.id }