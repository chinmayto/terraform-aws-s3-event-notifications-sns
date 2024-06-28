# Deploying an S3 Event Notification to SNS topic using Terraform
Deploying an S3 Event Notification to SNS topic using Terraform

In this blog post, we'll explore how to configure AWS S3 event notifications to send emails using SNS (Simple Notification Service) for S3 events. We'll leverage Terraform to automate the entire process.

## Architecture Overview
Before we get started, let's take a quick look at the architecture we'll be working with:

![alt text](/images/diagram.png)

### Step 1: Create an S3 Bucket
First, we need to create an S3 bucket where we will enable event notifications. Here is the Terraform code to create an S3 bucket:
```hcl
####################################################
# S3 static website bucket
####################################################
resource "aws_s3_bucket" "my-bucket" {
  bucket = var.bucket_name
}
```
### Step 2: Create an SNS Topic with Email Subscription
Next, we'll create an SNS topic and set up an email subscription to receive notifications. Below is the Terraform configuration for creating the SNS topic and the email subscription. Policy allows S3 to Publish events to SNS.

```hcl
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
}

resource "aws_sns_topic_subscription" "topic-email-subscription" {
  count     = length(var.email_address)
  topic_arn = aws_sns_topic.s3-event-notification-topic.arn
  protocol  = "email"
  endpoint  = var.email_address[count.index]
}
```
### Step 3: Create S3 Event Notifications
Finally, we configure the S3 bucket to send event notifications to the SNS topic. The following Terraform code snippet demonstrates how to set up S3 event notifications:
```hcl
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
```
## Steps to Run Terraform
Follow these steps to execute the Terraform configuration:
```hcl
terraform init
terraform plan 
terraform apply -auto-approve
```

Upon successful completion, Terraform will provide relevant outputs.
```hcl
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

## Testing
S3 Bucket with Event Notifications enabled 

![alt text](/images/s3bucket.png)
![alt text](/images/s3bucketnotification.png)

SNS Topic with email subscription (Confirm the subscription on email before performing any S3 activity)

![alt text](/images/sns.png)

File upload to create S3 event
![alt text](/images/fileupload.png)

Event notifications received via email
![alt text](/images/emailnotif.png)


## Cleanup
Remember to stop AWS components to avoid large bills.
```hcl
terraform destroy -auto-approve
```

## Conclusion
We have successfully configured AWS S3 event notifications to send emails using an SNS subscription. This setup can be particularly useful for monitoring and alerting purposes. 

## Resources
AWS S3 Notifications https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventNotifications.html

Github Link: https://github.com/chinmayto/terraform-aws-s3-event-notifications-sns

