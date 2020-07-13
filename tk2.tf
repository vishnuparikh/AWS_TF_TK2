//Vishnu Parikh
//github repo: https://github.com/vishnuparikh/AWS_TF_TK2.git


//user and variables//

provider "aws" {
  region     = "ap-south-1"
  profile    = "vmp"
}
variable "cidr_vpc" {
  description = "CIDR block for VPC"
  default = "10.1.0.0/16"
}

variable "cidr_subnet1" {
  description = "CIDR block for subnet"
  default = "10.1.0.0/24"
}


variable "cidr_subnet2" {
  description = "CIDR block for subnet"
  default = "10.1.1.0/24"
}


variable "availability_zone" {
  description = "availability zone to create subnet"
  default = "ap-south-1"
}


variable "environment_tag" {
  description = "Environment tag"
  default = "Production"

}


//creation private and public vpc//

resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr_vpc}"
  enable_dns_support   = true
  enable_dns_hostnames = true


  tags ={
    Environment = "${var.environment_tag}"
    Name= "Terraform_VPC"
  }
}
resource "aws_subnet" "public_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.cidr_subnet1}"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1a"
  tags ={
    Environment = "${var.environment_tag}"
    Name= "Public_Subnet"
  }

}
resource "aws_subnet" "private_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.cidr_subnet2}"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1a"
  tags ={
    Environment = "${var.environment_tag}"
    Name= "Private_Subnet"
  }

}


//creation Public facing internet gateway//

resource "aws_internet_gateway" "InterNetGateWay" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags ={
    Environment = "${var.environment_tag}"
    Name= "InternetGateWay"
  }

}
//creation routing table//

resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.vpc.id}"
route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.InterNetGateWay.id}"
  }
tags ={
    Environment = "${var.environment_tag}"
    Name= "RoutTable"
  }

}
resource "aws_route_table_association" "subnet_public" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public_route.id}"
}
resource "aws_route_table_association" "public_route_subnet" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public_route.id}"
}

//creation of security group for wordpress and mysql//

resource "aws_security_group" "sg_wp" {
  name = "sg_wordpress"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }


 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    Environment = "${var.environment_tag}"
    Name= "security_group1"
  }

}
resource "aws_security_group" "sg_mysql" {
  name = "sg_MYSQL"
  description = "managed by terrafrom for mysql servers"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = ["${aws_security_group.sg_wp.id}"]
  }


 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    Environment = "${var.environment_tag}"
    Name= "SG_MYSQL"
  }

}

//creation of 2 insatnce wordpress and mysql//

resource "aws_instance" "WP_Instance1" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_wp.id}"]
  key_name = "key1"
 tags ={
    Environment = "${var.environment_tag}"
    Name= "wordpress_OS"
  }

}
resource "aws_instance" "MYSQL_Instance2" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_mysql.id}"]
  key_name = "key1"
 tags ={
    Environment = "${var.environment_tag}"
    Name= "mysql_OS"
  }
}
