resource aws_s3_bucket s3bucket{
      bucket = "hampi-gulbarga-bucket"
      tags = {
          Name        = "MyBucket"
          Environment = "Dev"
      }
}
