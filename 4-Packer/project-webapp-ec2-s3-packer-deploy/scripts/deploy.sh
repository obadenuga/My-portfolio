#!/bin/bash

# Set AWS Variables
AWS_REGION="us-east-2"
BUCKET_NAME="my-static-website-$(date +%s)"
WEBSITE_PATH="../website"

echo "Starting deployment..."

# Step 1: Build EC2 AMI with Packer
echo "Building AMI with Packer..."
cd ../packer || exit
packer build web-app.json

# Step 2: Create an S3 Bucket
echo "Creating S3 bucket: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION

# Step 3: Upload Website Files to S3
echo "Uploading website files to S3..."
aws s3 sync $WEBSITE_PATH s3://$BUCKET_NAME/

# Step 4: Configure S3 Bucket for Static Website Hosting
echo "Configuring S3 bucket for static hosting..."
aws s3 website s3://$BUCKET_NAME/ --index-document index.html --error-document index.html

# Step 5: Apply Public Access Policy to the Bucket
echo "Applying public read access policy..."
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::'$BUCKET_NAME'/*"
        }
    ]
}'

# Step 6: Print the Website URL
echo "Deployment complete!"
echo "Your website is available at: http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"
