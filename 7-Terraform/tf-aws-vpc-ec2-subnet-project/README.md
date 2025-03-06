### Using Secure SSH Use Below SSH code
ssh -i ~/.ssh/secure-<used ssh id> ec2-user@<public IP>

### PING the PUblic IP From outside the EC2 instance 
PING <Public IP>

### Copy the .pem file from local machine to public instance DONT ADD ANY .pub or .pem to the name
scp -i ~/.ssh/<.pem filename> ~/.ssh/<.pem filename> ec2-user@<public instance>:~/.ssh/

### Give permissions to the .pem file  DONT ADD ANY .pub or .pem to the name
chmod 400 ~/.ssh/<.pemfilename>

## SSH into the Private Instance
ssh -i ~/.ssh/secure-key.pem ec2-user@<private-instance-ip>
ssh -i ~/.ssh/yes ec2-user@10.0.3.253

### PING the private IP
Ping <private IP>