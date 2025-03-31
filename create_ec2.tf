provider "aws" {
  region = "us-east-1"
  profile = "default"
  //access_key = "ASIAVADPE44WKJRLQLMW"
  //secret_key = "19CH/C3LFHTqx+evf8phHNOuU4f4Km07n7sRe4hZ"
  //token = "IQoJb3JpZ2luX2VjEEMaCXVzLXdlc3QtMiJHMEUCIQCL9esWWj47YwF/C7nS+SLlS93Z6/+xiasSnxPo8sn2awIgAMCYpipI+NOxRSIjpINXaMVt+UaEhCg5br9mN9zvSAkqtAIIrP//////////ARABGgwzNDM4MzA0ODg4NzYiDJoo1o2aNfjGXG8PUyqIAl4RRXwAKO+pDgFzv91Ke8+3i65dCLBxZOhpCi6gO2NUKGyimMCb/jstPbzlhkx0r9rZCZohqJFYrvCPkrk1S6PpnfMgSpr5Plv7iyFvR+Fi/ztpwPsWzsmI3pBNgC3XuuLxu3/1LRaPCkAbc6oVaUkMpWN/uWm+bRkmwOkLqqL/6jcXUEr0fg6nlRIP1P0afTWJ1qNfkKBB9JCQA0163KQK5VGv9bpt9J5AKlUhqR/ONQNHaKHXfJ+n+cn2cOcV2Akfz8Y5b0SB3A8YVT6+g6UfJNKsK1uabYeovRaptN2OOPZprPtm8kiioqjWEcCYT6ezq1M535qtghuTn4TzCjtt98hA7RPF+DCzvqu/BjqdAVmvXsgJqhMmiO2MTUWs0++4v28dt2/5PJesQccpwXrha5oSNwPsZz0RrKyOh5LJr0seWbFGojMweytqgZPEqnZHZEoxB183DGGXJ98XhjUj0WLPiEqJxT51H21953nAjOO1xPCNEOvG/SeZlpIvqeETeTwSogxRJrKnaAXG3439gmC+R88nPUg16bDI1B52SGv0X8OH1r+bIcJr6W8="
}

# 1. Create VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "custom-vpc"
  cidr = "10.10.0.0/16"
  azs = ["us-east-1a"]
  public_subnets  = ["10.10.1.0/24"]
  private_subnets = ["10.10.3.0/24"]
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
    cidr_blocks = ["0.0.0.0/0"]
    //cidr_blocks = ["172.59.161.109/32"] # Replace with your IP address
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

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.10.3.0/24"]
  }
  //depends_on = [aws_instance.ansible_controller]
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

# Provision Ansible Controller in Private Subnet
resource "aws_instance" "ansible_controller" {
  ami           = "ami-071226ecf16aa7d96"  # Replace with an appropriate AMI
  instance_type = "t2.micro"
  subnet_id     = module.vpc.private_subnets[0]
  security_groups = [aws_security_group.ec2_sg.id]
  key_name      = "MyEC2KeyPair"  # Replace with your SSH key

  tags = {
    Name = "Ansible-Controller"
  }
}


# 5. EC2 Instances in Private Subnets
resource "aws_instance" "private_instance" {
  count         = 6
  ami           = (count.index < 3 ? "ami-084568db4383264d4" : "ami-071226ecf16aa7d96") # Replace with your custom AMI ID
  instance_type = "t2.micro"
  subnet_id     = module.vpc.private_subnets[0] # all EC2 in same subnet
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = false
  key_name      = "MyEC2KeyPair" # Use your key pair name here

  tags = {
    Name = "PrivateInstance-${count.index + 1}"
    OS   = count.index < 3 ? "ubuntu" : "amazon"
  }
}


