# Server Monitoring

Monitoring an Ubuntu server effectively involves both manual checks and automated solutions. Here's how you can approach it and the steps you can take to study and master these skills:

### Manual Monitoring:

1. **Memory Usage** : Use the `free -m` command to check memory usage.
2. **Processor Usage** : Use the `top` or `htop` command to see CPU usage and running processes.
3. **Disk Usage** : Use the `df -h` command to check disk space usage.
4. **Network Usage** : Use the `ifconfig` or `ip a` command to check network interfaces and `netstat` to monitor network connections.

### Automated Monitoring:

1. **Install Monitoring Tools** :
- **Netdata** : Provides real-time performance monitoring. Install using `sudo apt-get install netdata`.
- **Prometheus and Grafana** : For more advanced monitoring and visualization. Prometheus collects metrics, and Grafana displays them. Follow [Prometheus]()  and [Grafana]()  installation guides.
2. **Set Up Alerts** : Configure alerts in Prometheus or use tools like Nagios to notify you of any critical issues.
3. **Log Management** : Use tools like ELK Stack (Elasticsearch, Logstash, Kibana) to manage and analyze logs from your server.
### Step-by-Step Guide to Study:
1. **Learn Basic Linux Commands** : Familiarize yourself with basic commands for checking system performance (`top`, `htop`, `free`, `df`, `netstat`).
2. **Explore Monitoring Tools** :
- **Netdata** : Start with Netdata for an easy-to-set-up real-time monitoring tool. Follow the [Netdata installation guide]() .
- **Prometheus & Grafana** : Learn how to set up Prometheus for collecting metrics and Grafana for visualization. Follow tutorials like this [Prometheus and Grafana setup guide]() .
3. **Set Up a Test Environment** : Create a virtual machine or use a cloud instance to practice installing and configuring these tools.
4. **Configure Alerts and Logs** : Learn how to set up alerts in Prometheus and explore log management with the ELK Stack. Follow the [ELK Stack guide](https://www.elastic.co/what-is/elk-stack) .
