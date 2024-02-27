resource "aws_iam_policy" "ssm_session_manager_policy" {
  name        = "SSMSessionManagerPolicy"
  path        = "/"
  description = "Allow SSM Session Manager access to instances."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "ssm:StartSession",
        Resource = "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:instance/*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:TerminateSession",
          "ssm:ResumeSession",
          "ssm:DescribeSessions"
        ],
        Resource = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:session/${aws_iam_user.ivan1.name}-*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:TerminateSession",
          "ssm:ResumeSession",
          "ssm:DescribeSessions"
        ],
        Resource = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:session/${aws_iam_user.assessment.name}-*"
      }
    ]
  })
}

resource "aws_iam_user" "ivan1" {
  name = "ivan1"
  path = "/"
}

resource "aws_iam_user" "assessment" {
  name = "assessment"
  path = "/"
}

resource "aws_iam_user_policy_attachment" "ivan1_ssm_attachment" {
  user       = aws_iam_user.ivan1.name
  policy_arn = aws_iam_policy.ssm_session_manager_policy.arn
}

resource "aws_iam_user_policy_attachment" "assessment_ssm_attachment" {
  user       = aws_iam_user.assessment.name
  policy_arn = aws_iam_policy.ssm_session_manager_policy.arn
}

output "ivan1_user" {
  value = aws_iam_user.ivan1.name
}

output "assessment_user" {
  value = aws_iam_user.assessment.name
}
