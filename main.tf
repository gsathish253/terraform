terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "tftraining2022remotebackend"
    key    = "webdev/my.tfstate"
    region = "ap-south-1"
   dynamodb_table = "mytableforlocking"
  }
}

resource "aws_vpc" "Main" {               
   cidr_block       = var.main_vpc_cidr     
   instance_tenancy = "default"
 }


resource "aws_internet_gateway" "IGW" {    
    vpc_id =  aws_vpc.Main.id            
 }


resource "aws_subnet" "publicsubnets" {    
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.public_subnets}"   
}

 resource "aws_subnet" "privatesubnets" {
   vpc_id =  aws_vpc.Main.id
   cidr_block = "${var.private_subnets}"   

}

resource "aws_route_table" "PublicRT" {   
    vpc_id =  aws_vpc.Main.id
         route {
    cidr_block = "0.0.0.0/0"              
    gateway_id = aws_internet_gateway.IGW.id
     }
 }     

resource "aws_route_table" "PrivateRT" {   
   vpc_id = aws_vpc.Main.id
   route {
   cidr_block = "0.0.0.0/0"            
   nat_gateway_id = aws_nat_gateway.NATgw.id
   }
 }

resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.publicsubnets.id
    route_table_id = aws_route_table.PublicRT.id
}

 resource "aws_route_table_association" "PrivateRTassociation" {
    subnet_id = aws_subnet.privatesubnets.id
    route_table_id = aws_route_table.PrivateRT.id
 }

resource "aws_eip" "nateIP" {
   vpc   = true
 }

 resource "aws_nat_gateway" "NATgw" {
   allocation_id = aws_eip.nateIP.id
   subnet_id = aws_subnet.publicsubnets.id
 }

resource "aws_security_group" "Sec_Group" {
  name = "Public"
  description = "Allow_ports"
  vpc_id = aws_vpc.Main.id

  
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  ingress {
    from_port = 80
    protocol = ""
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "EC2" {
  ami  = "ami-2757f631"
  instance_type = "t2.micro"
  #network_interface_id = aws_network_interface.PublicRT.id
}

