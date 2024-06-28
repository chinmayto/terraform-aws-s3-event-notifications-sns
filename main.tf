####################################################
# Create an S3 Bucket
####################################################
resource "aws_s3_bucket" "my-bucket" {
  bucket = var.bucket_name
  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-s3-bucket"
  })
}

####################################################
# Create an SNS topic with a email subscription
####################################################
resource "aws_sns_topic" "s3-event-notification-topic" {
  name   = "s3-event-notification-topic"
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[{
    "Effect": "Allow",
    "Principal": { "Service": "s3.amazonaws.com" },
    "Action": "SNS:Publish",
    "Resource": "arn:aws:sns:us-east-1:197317184204:s3-event-notification-topic",
    "Condition":{
        "StringEquals":{"aws:SourceAccount":"197317184204"},
        "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.my-bucket.arn}"}

    }
  }]
}
POLICY

  tags = merge(local.common_tags, {
    Name = "${local.naming_prefix}-sns-topic"
  })
}

resource "aws_sns_topic_subscription" "topic-email-subscription" {
  count     = length(var.email_address)
  topic_arn = aws_sns_topic.s3-event-notification-topic.arn
  protocol  = "email"
  endpoint  = var.email_address[count.index]
}


####################################################
# Creating Bucket Event Notification 
####################################################
resource "aws_s3_bucket_notification" "bucket-notification" {
  bucket = aws_s3_bucket.my-bucket.id
  topic {
    topic_arn = aws_sns_topic.s3-event-notification-topic.arn
    events    = ["s3:ObjectCreated:*"] # You can specify the events you are interested in
  }
}