resource "aws_lb" "assessment_alb" {
  name               = "assessment-alb"
  load_balancer_type = "application"
  subnets = ["subnet-0305d567c5d72e99b",
  "subnet-08b4293447af73f15"]

  security_groups = [
    aws_security_group.alb_sg.id
  ]
}

resource "aws_lb_target_group" "assessment_tg" {
  name     = "assessment-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-0a17825ff0ea85766"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/index.html"
    port                = "80"
    protocol            = "HTTP"
    matcher             = "200-299"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
  }
}

resource "aws_lb_listener" "assessment_frontend" {
  load_balancer_arn = aws_lb.assessment_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.assessment_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "assessment_instance_attachment" {
  target_group_arn = aws_lb_target_group.assessment_tg.arn
  target_id        = aws_instance.assessment_instance.id
  port             = 80
}
