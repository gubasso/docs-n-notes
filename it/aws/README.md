# AWS: Amazon Web Services

- ALB (Application Load Balancer).

- AZ: Availability Zones: isolated locations WITHIN an AWS region
  - Each region has multiple AZs (usually 3 or more)
  - AZs are physically separate, often miles apart, within a region
  - AZs are the building blocks for creating highly available, fault-tolerant systems in AWS.
- VPC: Virtual Private Cloud
- Subnets: range of IP addresses
  - Public: access to an Internet Gateway
    - For resources that need direct internet access (load balancer, bastion hosts)
  - Private: no access to Internet Gateway
    - For resources that don't need direct internet access (app servers, databases, cache)

- Subnet Groups: Create a subnet group for databases that spans the private subnets across AZs
  - e.g. 1 priv subnet at AZ 1, other priv subnet at AZ 2
    - both will be at a subnet group
    - This allows you to deploy databases in a highly available configuration
    - https://docs.aws.amazon.com/images/vpc/latest/userguide/images/vpc-example-private-subnets.png
    - https://docs.aws.amazon.com/images/vpc/latest/userguide/images/vpc-example-web-database.png

- security groups: virtual firewalls for each component (EC2 instance)
- network ACLs: virtual firewall for each subnet

- Elastic Load Balancing (Application Load Balancer) -> Auto Scaling groups

- EC2 provides virtual servers you can use to run any applications
- RDS offers managed relational databases without the operational overhead
- ElastiCache accelerates application performance with in-memory caching

Together, these services form the core of many cloud-based application architectures on AWS, handling the compute, database, and caching layers respectively. They integrate closely to enable building scalable, high-performance applications.
