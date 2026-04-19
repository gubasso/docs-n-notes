# AWS: EIP - Elastic IP Addresses

An Elastic IP address (EIP) is a static IPv4 address designed for dynamic cloud computing in Amazon Web Services (AWS). Here are the key points about Elastic IPs:

- An EIP is a public IPv4 address that you can allocate to your AWS account. It remains allocated until you explicitly release it.

- You can associate an EIP with any EC2 instance or network interface in your account, and reassociate it as needed. This allows you to mask the failure of an instance by rapidly remapping the EIP to another instance.

- The main use case for EIPs is to provide a persistent public IP address that can be programmatically remapped to point to a different instance, thus enabling you to hide instance or software failures.

- If an instance with an associated EIP is stopped or terminated, you can reassociate the EIP with a replacement instance to maintain a consistent public IP address.

- EIPs come from Amazon's pool of public IPv4 addresses or from a custom IP address pool you have brought to your AWS account.

- There is no charge for using an EIP while it is associated with a running instance. However, a small hourly fee applies if you have an EIP allocated but not associated with a running instance.

- By default, AWS accounts are limited to 5 EIPs per region to ensure the efficient utilization of public IPv4 addresses, which are a scarce resource. You can request an increase if needed.

So in summary, Elastic IP addresses provide a static, persistent public IPv4 address that you control, allowing you to dynamically remap public IP addresses to different EC2 instances as needed. This enables more flexibility and resiliency in cloud architectures.

Citations:
[1] https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
[2] https://docs.aws.amazon.com/pt_br/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
[3] https://docs.aws.amazon.com/vpc/latest/userguide/vpc-eips.html
[4] https://stackoverflow.com/questions/50306324/what-is-elastic-ip-in-aws-and-why-it-is-useful
[5] https://repost.aws/knowledge-center/intro-elastic-ip-addresses
[6] https://www.youtube.com/watch?v=UAdlVht4Xlw
[7] https://www.geeksforgeeks.org/aws-elastic-ip-addresses/
[8] https://intellipaat.com/blog/aws-elastic-ip/
