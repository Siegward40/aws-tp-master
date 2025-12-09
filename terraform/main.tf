resource "aws_vpc" "lab_vpc" {
name = "LabEC2Role"
assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}


data "aws_iam_policy_document" "ec2_assume_role_policy" {
statement {
actions = ["sts:AssumeRole"]
principals { type = "Service"; identifiers = ["ec2.amazonaws.com"] }
}
}


resource "aws_iam_role_policy" "ec2_policy" {
name = "LabEC2S3Policy"
role = aws_iam_role.ec2_role.id
policy = data.aws_iam_policy_document.ec2_s3_policy.json
}


data "aws_iam_policy_document" "ec2_s3_policy" {
statement {
actions = ["s3:PutObject","s3:GetObject","s3:ListBucket","s3:DeleteObject"]
resources = [aws_s3_bucket.app_bucket.arn, "${aws_s3_bucket.app_bucket.arn}/*"]
}
}


resource "aws_iam_instance_profile" "lab_instance_profile" {
name = "LabInstanceProfile"
role = aws_iam_role.ec2_role.name
}


# EC2 instance in public subnet us-east-1a
resource "aws_instance" "web" {
ami = data.aws_ami.ubuntu.id
instance_type = "t3.micro"
subnet_id = aws_subnet.public_a.id
key_name = var.ssh_key_name != "" ? var.ssh_key_name : null
associate_public_ip_address = true
vpc_security_group_ids = [aws_security_group.web_sg.id]
iam_instance_profile = aws_iam_instance_profile.lab_instance_profile.name


user_data = file("${path.module}/userdata.sh")


tags = { Name = "lab-web-ec2" }
}


data "aws_ami" "ubuntu" {
most_recent = true
owners = ["099720109477"] # Canonical
filter { name = "name"; values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"] }
}