# AWS: Network ACLs (Access Control Lists)

Network ACLs (Access Control Lists) are virtual firewalls at the subnet level in AWS that control inbound and outbound traffic. Here are the key points about network ACLs:

1. Subnet-level firewall:
- Network ACLs operate at the subnet level, controlling traffic entering and leaving each subnet
- They provide an additional layer of security on top of security groups, which operate at the instance level

2. Stateless rules:
- Network ACL rules are stateless, meaning return traffic must be explicitly allowed by rules
- If you allow inbound traffic, you must create a separate rule to allow the corresponding outbound traffic
- This is in contrast to security groups, which are stateful (automatically allow return traffic)

3. Rule ordering:
- Network ACL rules are evaluated in numerical order, starting with the lowest numbered rule
- As soon as a rule matches traffic, it's applied regardless of any higher-numbered rule that may contradict it
- This allows for very granular traffic control, but can also lead to unintended behavior if not configured carefully

4. Allow and deny rules:
- Each network ACL rule can either allow or deny traffic
- By default, a network ACL allows all inbound and outbound traffic
- You can add rules to block specific traffic as needed

5. Rule components:
- Each rule specifies a protocol (e.g., TCP, UDP, ICMP), source/destination IP range (CIDR), and port range
- For TCP and UDP, you can specify ports; for ICMP, you specify the code and type

6. VPC automatically applies network ACLs:
- Your VPC automatically comes with a modifiable default network ACL
- By default, it allows all inbound and outbound traffic
- You can create custom network ACLs and associate them with specific subnets as needed

7. Ephemeral ports:
- If your application uses a response port different than the request port, you must open ephemeral ports (1024-65535)
- This is a common gotcha with network ACLs that can cause unexpected traffic blocking

In summary, network ACLs provide a subnet-level firewall with stateless rules to control inbound and outbound traffic in your VPC. They complement security groups and allow for granular traffic filtering based on IP ranges, protocols, and ports. Properly configuring network ACLs is an important part of a defense-in-depth strategy for securing your AWS infrastructure.
