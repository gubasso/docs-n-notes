# Monitoring / Observability / Logging


## CloudTrail-CloudWatch Integration

- You can configure CloudTrail to deliver logs to a CloudWatch Logs log group in addition to S3
- This allows you to analyze CloudTrail events in real-time with CloudWatch Logs
- Benefits of sending CloudTrail logs to CloudWatch:
  - Monitor events in near real-time instead of waiting for delivery to S3
  - Use CloudWatch Logs filter expressions to find specific events
  - Create metric filters to count the occurrences of specific events and trigger alarms
  - Visualize event occurrences on CloudWatch dashboards
- To set up the integration:
  1. Create a trail in CloudTrail
  2. Choose a CloudWatch Logs log group as a delivery endpoint
  3. Specify an IAM role for CloudTrail to assume for delivering logs to CloudWatch
- CloudTrail will then stream events to CloudWatch Logs in addition to S3
- You can view the events in the CloudWatch console and create metrics/alarms

So in summary, CloudTrail records API activity and account events, acting as the auditing source. CloudWatch Logs can ingest the CloudTrail logs, allowing you to monitor, analyze, and alert on the auditing data in near real-time. The integration provides a powerful auditing and security analysis solution, combining CloudTrail's comprehensive logging with CloudWatch's monitoring and observability features.

## AWS CloudWatch vs Prometheus/Grafana

Here is a summary comparing AWS CloudWatch and Prometheus/Grafana for monitoring:

Key similarities:
- Both are used for monitoring, logging, and alerting on application and infrastructure metrics
- Both can collect metrics from various AWS services and custom applications
- Both support graphing, dashboarding, and setting up alerts based on metrics

Key differences:

Data storage and querying:
- CloudWatch stores metrics within AWS. You query metrics directly from CloudWatch.
- Prometheus pulls metrics from monitored targets and stores them in its own time-series database. Grafana queries this Prometheus database.
- Prometheus has a more powerful query language (PromQL) compared to CloudWatch.

Monitoring scope:
- CloudWatch is AWS-native and designed primarily for monitoring AWS services and resources.
- Prometheus is platform-agnostic and commonly used for Kubernetes and cloud-native stack monitoring. It can monitor AWS resources using exporters.

Dashboarding and visualization:
- Grafana provides richer dashboarding and visualization capabilities compared to CloudWatch dashboards.
- CloudWatch charges for each additional dashboard, while Grafana dashboards are free.

Cross-account, cross-region monitoring:
- Prometheus enables easier querying across accounts, regions, and services using PromQL.
- CloudWatch requires setting up multiple data sources to achieve this.

Pricing:
- CloudWatch has a pay-per-metric model that can get expensive at scale.
- Prometheus is open-source and free, but you pay for the infrastructure to run it.

Operational overhead:
- CloudWatch is fully managed by AWS, requiring less operational work.
- Running your own Prometheus/Grafana stack requires more setup and maintenance.

So in summary, CloudWatch is well-suited if your workloads are primarily on AWS and you want a managed monitoring solution. Prometheus/Grafana is preferred for Kubernetes and cloud-native environments, cross-platform monitoring, and more flexibility and control over your monitoring setup. Many organizations also use them together, with Prometheus for granular metrics and CloudWatch for high-level AWS service monitoring.

The choice depends on your specific monitoring needs, existing AWS usage, and willingness to manage your own monitoring infrastructure. A combined approach leveraging both systems is also viable for comprehensive observability.

Citations:
[1] https://www.infracloud.io/blogs/prometheus-vs-cloudwatch/
[2] https://grafana.com/blog/2024/05/22/how-to-visualize-amazon-cloudwatch-metrics-in-grafana/
[3] https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-IM-use-cases.html
[4] https://grafana.com/docs/grafana/latest/fundamentals/intro-to-prometheus/
[5] https://www.metricfire.com/blog/prometheus-vs-cloudwatch/
