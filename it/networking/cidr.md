# Networking: CIDR


A CIDR block (Classless Inter-Domain Routing) is a concise way to specify a range of IP addresses for a network. It consists of an IP address followed by a slash and a number that indicates how many bits are used for the network portion of the address.

In the example "10.0.0.0/16":

- "10.0.0.0" is the starting IP address of the network
- "/16" means that the first 16 bits (out of 32 total for IPv4) are used to define the network
  - The remaining 16 bits can be used for host addresses within the network

The "/16" notation allows for a range of 65,536 possible IP addresses (2^16), from 10.0.0.0 to 10.0.255.255.

When creating a VPC in AWS, you define a primary CIDR block for the entire VPC. This is the overall IP address range that your VPC will use. All subnets and resources within the VPC will have IP addresses within this CIDR block.

For example, if you define your VPC's CIDR block as 10.0.0.0/16, you could then create subnets with smaller CIDR blocks within this range, like:

- 10.0.1.0/24 (256 addresses)
- 10.0.2.0/24 (256 addresses)
- 10.0.3.0/24 (256 addresses)

This allows you to organize and allocate IP addresses within your VPC in a structured manner. The CIDR block you choose for your VPC should be large enough to accommodate all the subnets and resources you plan to create, but not so large that it wastes a significant portion of the private IP address space.

---

CIDR (Classless Inter-Domain Routing) notation is a compact way to specify the network prefix of an IP address. It appends a suffix to the IP address indicating the number of significant bits that comprise the network portion.

The CIDR suffix determines the size of the network and number of available host addresses:

- /8 means the first 8 bits are the network portion, leaving 24 bits for host addressing
  - Example: 10.0.0.0/8 has a network portion of 10 and can accommodate 16,777,214 hosts

- /16 means the first 16 bits are the network, leaving 16 bits for hosts
  - Example: 172.16.0.0/16 has a network of 172.16 and 65,534 possible hosts

- /24 means the first 24 bits are the network, leaving 8 bits for hosts
  - Example: 192.168.1.0/24 has a network of 192.168.1 and 254 possible hosts

So the key points are:

1. The /xx notation specifies how many leading bits represent the network
2. As the number after / gets larger, the network size gets smaller and supports fewer hosts
3. It allows flexible allocation of IP address blocks to organizations based on their network size requirements

CIDR replaced the older classful networking architecture (Class A, B, C). Its advantages include:

- More efficient use of IPv4 address space by allowing variable-length subnetting
- Enables route aggregation to reduce the size of routing tables
- Provides greater flexibility compared to the rigid class-based system

So in summary, CIDR notation allows specifying networks of arbitrary sizes in a compact format. The /xx suffix is the network prefix length and determines the maximum number of hosts that network supports. Understanding CIDR is crucial for subnetting, route summarization, and efficient utilization of IP address blocks.

Citations:
[1] https://superuser.com/questions/1464492/what-does-16-24-mean-with-regards-to-ip-addresses
[2] https://www.ripe.net/about-us/press-centre/understanding-ip-addressing/
[3] https://www.digitalocean.com/community/tutorials/understanding-ip-addresses-subnets-and-cidr-notation-for-networking
[4] https://aws.amazon.com/what-is/cidr/
[5] https://serverfault.com/questions/1028435/how-can-we-explain-cidr-notation-with-24-and-32-to-a-manager
[6] https://www.freecodecamp.org/news/subnet-cheat-sheet-24-subnet-mask-30-26-27-29-and-other-ip-address-cidr-network-references/
