variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "repo_url" {}

provider "aws" {
  region     = "us-east-1"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

data "aws_ami" "centos" {
  owners      = ["679593333241"]
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "do-lab" {
  ami = "${data.aws_ami.centos.id}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet-uno.id}"
  associate_public_ip_address = "true"
  root_block_device {
    delete_on_termination = "true"
  }
  user_data = <<-EOF
              #!/bin/bash
              yum install -y docker git openssl
              service docker restart
              curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /bin/docker-compose
              sudo chmod +x /bin/docker-compose
              git clone ${var.repo_url}
              cd do-lab
              PASSWORD=$(openssl rand -base64 12)
              sed -i "s/password/$${PASSWORD}/" .env
              /bin/docker-compose up --build
              EOF
  tags {
    Name = "do-lab"
  }
  security_groups = ["${aws_security_group.do-lab.id}"]
  tags = {
    Name = "do-lab"
  }
}


resource "aws_eip" "do-lab" {
  instance = "${aws_instance.do-lab.id}"
  vpc      = true
}

resource "aws_internet_gateway" "do-lab" {
  vpc_id = "${aws_vpc.do-lab.id}"
tags {
    Name = "do-lab"
  }
}
resource "aws_route_table" "do-lab" {
  vpc_id = "${aws_vpc.do-lab.id}"
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.do-lab.id}"
  }
tags {
    Name = "do-lab"
  }
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.subnet-uno.id}"
  route_table_id = "${aws_route_table.do-lab.id}"
}

resource "aws_vpc" "do-lab" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags {
    Name = "do-lab"
  }
}
resource "aws_subnet" "subnet-uno" {
  cidr_block = "${cidrsubnet(aws_vpc.do-lab.cidr_block, 3, 1)}"
  vpc_id = "${aws_vpc.do-lab.id}"
  availability_zone = "us-east-1a"
}
resource "aws_security_group" "do-lab" {
  name = "do-lab"
  vpc_id = "${aws_vpc.do-lab.id}"
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    protocol = "-1"
  }
}

output "app_endpoint" {
  value = "http://${aws_eip.do-lab.public_ip}/"
}
