# My-portfolio

#### The Project-log-monitor-cloudwatch.
### The codes will run into an error during bnucket creation.
### Follow these Steps to complete the project:
### Disable Block Public Access for the S3 Bucket
### You need to manually disable the Block Public Access setting for the bucket.
### Go to the AWS S3 Console: S3 Console
### Select your bucket: my-unique-bucket-302011050.
### Click on Permissions.
### Under "Block public access (bucket settings)", click Edit.
### Uncheck the setting "Block public access to buckets and objects granted through new public bucket policies".
###Save changes.
### Then, re-run: (Terraform init && terraform validate)
### terraform apply
### Run terraform destroy to remove all provisoned infrastructure
