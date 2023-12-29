# AWS AMI Data Query for CentOS-8-DevOps-Practice
data "aws_ami" "example" {
  owners      = ["973714476881"]
  most_recent = true
  name_regex  = "Centos-8-DevOps-Practice"
}

# AWS Security Group Configuration
resource "aws_security_group" "sg" {
  name        = var.name
  description = "Allow TLS inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.name
  }
}

# AWS EC2 Instance Configuration
resource "aws_instance" "web" {
  ami           = data.aws_ami.example.id
  instance_type = "t3.small"

  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = var.name
  }
}

# Creates an AWS Route 53 record in the specified hosted zone
resource "aws_route53_record" "www" {
  zone_id = "Z09157091J32F5PJ5K67Y"
  name    = "${var.name}-dev"
  type    = "A"
  ttl     = 30
  records = [aws_instance.web.private_ip]
}

# Establishes SSH connection on a CentOS machine, installs/configures Ansible, and runs playbooks in dev env from a GitHub repository.
resource "null_resource" "ansible" {
  depends_on = [aws_instance.web, aws_route53_record.www]

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "centos"
      password = "DevOps321"
      host     = aws_instance.web.public_ip
    }

    inline = [
      "sudo labauto ansible",
      "ansible-playbook main.yml -e ansible_user=centos -e ansible_password=DevOps321 -e role_name=${var.name} -e env=dev -i ${var.name}-dev.robobal.store,"
    ]
  }
}

variable "name" {}
