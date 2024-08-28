# Security: Bastion Hosts

Bastion hosts, also known as jump servers, are special-purpose computers designed to be the primary access point from the Internet into a private network or VPC (Virtual Private Cloud). They act as a secure gateway for administrators and authorized users to connect to resources in private subnets, without exposing those resources directly to the public internet.

Key characteristics and functions of bastion hosts:

1. Hardened security: Bastion hosts are typically hardened, meaning they have strict security configurations and minimal software installed to reduce the attack surface.

2. Placed in public subnet: Bastion hosts are usually placed in a public subnet with a public IP address, making them accessible from the internet.

3. Access control: They often have strict security group rules that limit inbound traffic to specific IP addresses or ranges, and only allow necessary outbound traffic.

4. Secure access protocols: Administrators usually connect to the bastion host using secure protocols like SSH (Secure Shell) for Linux or RDP (Remote Desktop Protocol) for Windows.

5. Jumping to private resources: Once connected to the bastion host, administrators can then "jump" to other servers or resources in private subnets to perform necessary tasks.

In a typical AWS architecture:

- The bastion host is placed in a public subnet
- It has a public IP address and is accessible from the internet
- Security group rules allow inbound SSH/RDP from trusted IP addresses
- Administrators SSH/RDP to the bastion host
- From there, they can connect to EC2 instances, RDS databases, etc. in private subnets

The use of bastion hosts adds an extra layer of security to the network architecture. By preventing direct access to private resources and forcing all connections through a hardened, monitored jump server, the risk of unauthorized access or attacks is greatly reduced. Bastion hosts are a key component in implementing secure, multi-tier architectures in the cloud.
