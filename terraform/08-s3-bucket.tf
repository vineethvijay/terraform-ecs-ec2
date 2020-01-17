resource "aws_s3_bucket" "s3_bucket" {
  bucket = "zz-test-ecs-write-bucket"
  acl = "private"
}

/*
resource "aws_s3_bucket_public_access_block" "block_s3_public_access" {
  bucket = "${aws_s3_bucket.s3_bucket.id}"

  block_public_acls   = true
  block_public_policy = true
}
*/
