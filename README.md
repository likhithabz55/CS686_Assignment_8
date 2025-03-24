                                                    Packer & Terraform


This is a sample project where we use packer and Terraform to create and provision custom AMI, VPC, subnets and EC2 instances.

A.  Create a custom AWS AMI using Packer that contains the following:
Amazon Linux
Docker
Your SSH public key is set so you can login using your private key


To create a custom AWS AMI with the above specifications using packer,
We need to build the packer.json file.
Make the below changes in the file to run locally.


Update region, instance_type and aws_key_pair_name inside variables.
Aws_key_pair_name will be the name of the KeyPair we create on AWS console and whose private key we use to access instances.
Update the path to private SSH key (.pem file) inside the builders.
           


Then save the file and use the below command for build.
    
packer build packer.json


This will create a custom AMI with the above requirements.





B. Terraform scripts to provision AWS resources:


VPC, private subnets, public subnets, all necessary routes (use modules)


1 bastion host in the public subnet (accept only your IP on port 22)


6 EC2 instances in the private subnet using your new AMI created from Packer


To implement part B, install terraform in your system locally from the below page


https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli


The file create_vpc.tf contains code to provision all the above instances.


Replace the region in the first two blocks with the appropriate region name.
          
          


Inside the block bastion_sg, replace the ip address with public ip of device you want to access bastion host from.
           


Replace the ami id with ami id you created  with packer.json in part A inside the blocks bastion_host and private_instance.


           





Now run the below commands to provision instances.


terraform init
terraform plan
terraform apply


To access private ec2 instances from bastion host , first copy your private key to bastion host and then use it to ssh it to private instances.
      

