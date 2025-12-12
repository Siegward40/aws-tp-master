# ------------------------------
# 1️⃣ VPC + subnets + IGW + route tables
# ------------------------------
resource "aws_vpc" "lab_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "lab-vpc" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "public-us-east-1a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "public-us-east-1b" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.lab_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "private-us-east-1a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.lab_vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "private-us-east-1b" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lab_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta_pub_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "rta_pub_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# ------------------------------
# 2️⃣ Security Groups
# ------------------------------
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.lab_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "web-sg" }
}

resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = aws_vpc.lab_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "db-sg" }
}

# ------------------------------
# 3️⃣ S3 Bucket privé
# ------------------------------
resource "aws_s3_bucket" "app_bucket" {
  bucket = var.app_bucket_name
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.app_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------
# 5️⃣ DB Subnet Group
# ------------------------------
resource "aws_db_subnet_group" "dbsub" {
  name       = "lab-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  tags       = { Name = "lab-db-subnet-group" }
}

# ------------------------------
# 6️⃣ RDS MySQL (single-AZ)
# ------------------------------
resource "aws_db_instance" "app_db" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = "labpassword123"
  db_subnet_group_name   = aws_db_subnet_group.dbsub.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = true
  tags                   = { Name = "lab-rds-mysql" }
}

#provider "mysql" {
#  endpoint = aws_db_instance.app_db.address
#  username = var.db_username
#  password = "labpassword123"
#  tls      = false  # si tu n’utilises pas SSL
#}

#resource "mysql_database" "appdb" {
#  name = "app_db"
#}



# ------------------------------
# 7️⃣ EC2 Instance
# ------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_a.id
  key_name                    = var.ssh_key_name != "" ? var.ssh_key_name : null
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  user_data                   = file("${path.module}/userdata.sh")
  tags                        = { Name = "lab-web-ec2" }
}

# ------------------------------
# 8️⃣ Outputs
# ------------------------------
output "ec2_public_ip" {
  description = "IP publique de l'EC2"
  value       = aws_instance.web.public_ip
}

output "rds_endpoint" {
  description = "Endpoint RDS privé"
  value       = aws_db_instance.app_db.address
}

output "db_password" {
  description = "Mot de passe DB généré"
  value       = "labpassword123"
  sensitive   = false
}

output "s3_bucket" {
  description = "Nom du bucket S3"
  value       = aws_s3_bucket.app_bucket.id
}

output "db_username" {
  value = var.db_username
}