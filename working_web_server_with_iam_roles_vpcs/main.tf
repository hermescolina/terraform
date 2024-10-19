provider "aws" {
  region = "us-east-1" # Change to your desired region
}

# Create an IAM Role for SSM
resource "aws_iam_role" "ssm_role" {
  name = "my_ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

# Attach the custom SSM permissions policy to the IAM Role
resource "aws_iam_role_policy" "ssm_custom_policy" {
  name   = "MySSMCustomPolicy"
  role   = aws_iam_role.ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssm:CreateAssociation",
          "ssm:UpdateAssociation",
          "ssm:DeleteAssociation",
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListAssociations",
          "ssm:GetConnectionStatus",
          "ssm:DescribeInstanceProperties"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the SSM managed policy to the IAM Role
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create IAM Instance Profile
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "my_ssm_instance_profile"
  role = aws_iam_role.ssm_role.name
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16" # Adjust as needed
}

# Create an Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create a subnet in the VPC
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24" # Adjust as needed
  availability_zone       = "us-east-1a" # Change to your desired AZ
  map_public_ip_on_launch = true
}

# Create a route table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create a security group
resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my_vpc.id
  name   = "my_security_group"

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ICMP traffic (for ping)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance with a web server and "Hello World" page
resource "aws_instance" "my_instance" {
  ami                    = "ami-06b21ccaeff8cd686" # Specified AMI ID
  instance_type          = "t2.micro" # Free tier eligible instance
  subnet_id              = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]

  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name

  # User data to install Apache and create a simple web page
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "<html><h1>Hello World from Terraform!</h1></html>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "MyFirstInstance"
  }
}
