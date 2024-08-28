# AWS CloudTrail

- CloudTrail is a service that enables governance, compliance, operational auditing, and risk auditing of your AWS account
- It records AWS API calls and other account activity and delivers log files to you
- CloudTrail is enabled by default for all AWS accounts and records the last 90 days of account activity for free in the Event History
- You can create trails to persistently store and access CloudTrail logs:
  - A trail can log events from either a single region or all regions
  - Trails can log management events (control plane operations), data events (high-volume data plane operations), and CloudTrail Insights events (unusual activity)
  - Logs can be stored in S3 buckets and optionally delivered to CloudWatch Logs
