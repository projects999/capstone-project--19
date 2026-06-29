resource "aws_s3_bucket" "backup_bucket" {
  bucket = "project-19-backup-bucket"
}
resource "aws_s3_bucket_policy" "https_only" {

  bucket = aws_s3_bucket.backup_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid = "DenyInsecureTransport"

        Effect = "Deny"

        Principal = "*"

        Action = "s3:*"

        Resource = [
          aws_s3_bucket.backup_bucket.arn,
          "${aws_s3_bucket.backup_bucket.arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }

        Principal = "*"
      }
    ]
  })
}

data "aws_ami" "ec2-ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }
}

resource "aws_iam_role" "s3-access-role" {
  name = "s3-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "s3:*"
      }
    ]
  })
}

resource "aws_iam_policy" "s3-access-policy" {
  name = "s3-access-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2-role-attachment" {
  role       = aws_iam_role.s3-access-role.name
  policy_arn = aws_iam_policy.s3-access-policy.arn
}

resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.s3-access-role.name
}
resource "aws_instance" "ec2-instance" {
  ami                  = data.aws_ami.ec2-ami.id
  instance_type        = "t4g.small"
  depends_on           = [aws_iam_instance_profile.ec2-instance-profile]
  iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.name
  tags = {
    name = "ec2-project-19"
  }
  root_block_device {
    volume_size = 15
    volume_type = "gp2"
  }
}
