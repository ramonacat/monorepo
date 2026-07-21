resource "aws_s3_bucket" "attic" {
  provider = aws.rustfs

  bucket = "attic"
}
