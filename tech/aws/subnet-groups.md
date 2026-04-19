# AWS: Subnet Groups

A subnet group in AWS is a collection of subnets (typically private) designated for a specific purpose
The main use case is for databases (RDS, Aurora, Redshift) and caching (ElastiCache)
When launching a database instance, you specify a subnet group for it to use
The database will have a network interface in each subnet of the group
This allows the database to span multiple Availability Zones for high availability
Subnet grou
