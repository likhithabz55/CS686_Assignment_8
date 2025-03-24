provider "aws" {
  region = "us-east-1"
}

# 1. Create VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "custom-vpc"
  cidr = "10.10.0.0/16"
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnets = ["10.10.3.0/24", "10.10.4.0/24"]
  enable_nat_gateway = true
}

# 2. Create Bastion Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Allow SSH access from your IP to bastion host"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["98.248.69.96/32"] # Replace with your IP address
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Create EC2 Security Group for Instances
 resource "aws_security_group" "ec2_sg" {
   name        = "ec2_sg"
   description = "Allow internal communication for EC2 instances"
   vpc_id      = module.vpc.vpc_id

   egress {
     from_port = 0
     to_port   = 0
     protocol  = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     from_port = 0
     to_port   = 65535
     protocol  = "tcp"
     cidr_blocks = ["10.0.0.0/16"] # Allow communication within the VPC
   }

   ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["${aws_instance.bastion_host.private_ip}/32"] # Add the Bastion Host's private IP or CIDR
  }
 }

 # 4. Bastion Host in Public Subnet
resource "aws_instance" "bastion_host" {
  ami           = "ami-0b49fb0aa38309880"
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name      = "MyEC2KeyPair" //add key-pair name
  associate_public_ip_address = true

  tags = {
    Name = "BastionHost"
  }
}

# 5. EC2 Instances in Private Subnets
resource "aws_instance" "private_instance" {
  count         = 6
  ami           = "ami-0b49fb0aa38309880" # Replace with your custom AMI ID
  instance_type = "t2.micro"
  subnet_id     = module.vpc.private_subnets[count.index % 2] # Distribute across subnets
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name      = "MyEC2KeyPair" # Use your key pair name here

  tags = {
    Name = "PrivateInstance-${count.index + 1}"
  }
}


