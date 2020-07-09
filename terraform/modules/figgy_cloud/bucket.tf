# This is optional, you may also select an existing bucket, feel free to comment out.
# If you comment this out, ensure your bucket exists, and then comment out delete the `depends_on` blocks  referencing
# `aws_s3_bucket.figgy_bucket` in the files prefixed with `lambda_`
resource "aws_s3_bucket" "figgy_bucket" {
  count  = var.cfgs.create_deploy_bucket == true ? 1 : 0
  bucket = var.deploy_bucket
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name       = "figgy"
    run_env    = var.run_env
    created_by = "figgy"
  }

  provisioner "local-exec" {
    command = "echo \"Sleeping for 15s to address potential race condition\" && sleep 15"
  }
}

# You will need this if you do **_NOT_** already have cloud-trail logging events
# Generally I would not recommend using figgy to manage your cloudtrail, but this will ensure your events are properly
# capture and figgy can use them for its event-driven config workflow :)
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  count  = var.cfgs.create_deploy_bucket == true && var.cfgs.configure_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.figgy_bucket[0].id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.figgy_bucket[0].id}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.figgy_bucket[0].id}/AWSLogs/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY

  depends_on = [aws_s3_bucket.figgy_bucket]

}

resource "aws_cloudtrail" "figgy_cloudtrail" {
  count                         = var.cfgs.create_deploy_bucket == true && var.cfgs.configure_cloudtrail ? 1 : 0
  name                          = "figgy-trail"
  s3_bucket_name                = var.deploy_bucket
  include_global_service_events = false
  depends_on                    = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}