


## Creating SSH Key Pairs
```bash
# For us-east-1
aws ec2 create-key-pair --key-name vpc-peering-demo --region us-east-1 --query 'KeyMaterial' --output text > vpc-peering-demo.pem

# For us-west-2
aws ec2 create-key-pair --key-name vpc-peering-demo --region us-west-2 --query 'KeyMaterial' --output text > vpc-peering-demo-west.pem

# Set permissions (on Linux/Mac)
chmod 400 vpc-peering-demo.pem
chmod 400 vpc-peering-demo-west.pem
```

## Pending

- Create additional EC2 instances
- Set up a VPN connection
- Implement Transit Gateway for complex topologies