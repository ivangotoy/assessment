data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_iam_role" "ssm_ec2_role" {
  name = "SSM_EC2_Role"

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

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_instance" "assessment_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"

  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum upgrade -y
                amazon-linux-extras install -y kernel-ng
                amazon-linux-extras install nginx1.12 -y
                systemctl start nginx
                systemctl enable nginx

		yum install -y selinux-policy selinux-policy-targeted
                setenforce 1
                sed -i 's/^SELINUX=disabled/SELINUX=enforcing/' /etc/selinux/config
                sed -i 's/^SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config

                yum install -y amazon-ssm-agent
                systemctl enable amazon-ssm-agent
                systemctl start amazon-ssm-agent

                sudo yum install fail2ban -y
                sudo systemctl start fail2ban
                sudo systemctl enable fail2ban
                
                sudo amazon-linux-extras install ansible2 -y

                echo '<!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>Success</title>
                </head>
                <body>
                    <h1>Congratulations, you've reached the hardened instance!</h1>
                </body>
                </html>' | sudo tee /usr/share/nginx/html/index.html

                echo 'server {
                    listen 80;
                    server_name _;
                    return 301 https://\$host\$request_uri;
                }

                server {
                    listen 443 ssl;
                    server_name _;

                    ssl_certificate     /etc/nginx/ssl/nginx.crt;
                    ssl_certificate_key /etc/nginx/ssl/nginx.key;

                    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
                    add_header Content-Security-Policy "default-src 'self'; script-src 'self' https://trustedscripts.example.com; object-src 'none';";
                    add_header X-XSS-Protection "1; mode=block";

                    location / {
                        root   /usr/share/nginx/html;
                        index  index.html index.htm;
                    }
                }' | sudo tee /etc/nginx/conf.d/default.conf

                sudo mkdir -p /etc/nginx/ssl
                sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt -subj "/CN=localhost"

                sudo systemctl reload nginx

                sudo reboot
              EOF

  tags = {
    Name = "Hardened-prod-instance"
  }
}

resource "aws_shield_protection" "assessment_shield_protection" {
  name         = "assessment-shield-protection"
  resource_arn = aws_instance.assessment_instance.arn
}


resource "aws_inspector_assessment_template" "assessment" {
  name               = "example-assessment"
  duration           = 3600
  rules_package_arns = ["arn:aws:inspector:${var.aws_region}:${var.aws_account_id}:rulespackage/0-xxxxxxxxxx"]
  target_arn         = aws_instance.assessment_instance.arn
}
