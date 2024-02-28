data "aws_ami" "latest_amazon_linux" {
  owners = ["amazon"]
  filter {
    name   = "image-id"
    values = ["ami-0440d3b780d96b29d"]
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "my-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "ssm_role_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::${var.aws_account_id}:policy/SSMSessionManagerPolicy"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "my-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "assessment_instance" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = "subnet-0305d567c5d72e99b"
  key_name                    = "AssesmentKey"
  security_groups             = [aws_security_group.instance_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name

  user_data = file("userdata.sh")

  tags = {
    Name   = "Hardened-prod-instance",
    Backup = "true"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "assessment_alb_sg"
  description = "Security group for ALB"
  vpc_id      = "vpc-0a17825ff0ea85766"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "assessment_instance_sg"
  description = "Security group for EC2 instance"
  vpc_id      = "vpc-0a17825ff0ea85766"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
