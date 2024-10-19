provider "aws" {
  region = "us-east-1" # Change this to your desired region
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MyVPC"
  }
}

# Create a Subnet
resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Change this based on your availability zone
  tags = {
    Name = "MySubnet"
  }
}

# Create an EC2 instance
resource "aws_instance" "my_instance" {
  ami           = "ami-06b21ccaeff8cd686" # Replace with your valid AMI ID
  instance_type = "t2.micro" # Free tier eligible instance
  subnet_id     = aws_subnet.my_subnet.id # Reference to the subnet

  tags = {
    Name = "MyFirstInstance"
  }
}
