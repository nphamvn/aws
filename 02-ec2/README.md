### Instroduction
Create an EC2 instance allow all inbound and outbound traffic.
After creation, we will confirm that we can ping the instance from our local machine as well as SSH into it.

### Prepare
Run below command to generate a key pair for SSH access to EC2 instance.

```bash
ssh-keygen -f id -N ""
```