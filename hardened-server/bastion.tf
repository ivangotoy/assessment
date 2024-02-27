provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "ssm_role" {
  name = "SSMRoleForBastion"

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

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSMInstanceProfileForBastion"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "bastion" {
  ami           = "ami-0440d3b780d96b29d"
  instance_type = "t2.micro"
  subnet_id     = "subnet-02ef55da883af4d10"
  key_name      = "AssesmentKey"

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  # This script ensures the SSM agent is installed and running
  user_data = <<-EOF
                #!/bin/bash
		yum update -y
		yum upgrade -y
                yum install -y amazon-ssm-agent
                systemctl enable amazon-ssm-agent
                systemctl start amazon-ssm-agent
		yum install fail2ban -y
                systemctl start fail2ban
                systemctl enable fail2ban
		amazon-linux-extras install -y kernel-ng
		NEW_KERNEL=$(rpm -q kernel-ng | tail -n 1)
                CURRENT_KERNEL=$(uname -r)

                yum install -y selinux-policy selinux-policy-targeted
                setenforce 1
                sed -i 's/^SELINUX=disabled/SELINUX=enforcing/' /etc/selinux/config
                sed -i 's/^SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config

                if [[ "$NEW_KERNEL" != "kernel-ng-$CURRENT_KERNEL" ]]; then
                  echo "Rebooting for new kernel..."
                  shutdown -r +1 "Rebooting for new kernel..."
                else
                  echo "No reboot needed"
                fi
              EOF

  tags = {
    Name = "BastionHost"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Allows traffic only from Systems Manager"
  vpc_id      = "vpc-009199cd981de7c83"

  egress {
    description = "Allow all outbound traffic by default"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "BastionSecurityGroup"
  }
}
