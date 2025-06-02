# AWS SOC Dashboard Project 🛡️

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=flat&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=flat&logo=grafana&logoColor=white)](https://grafana.com/)

A comprehensive Security Operations Center (SOC) dashboard that provides real-time visualization and monitoring of AWS WAF traffic logs and VPC Flow Logs. This project enables security teams to detect and respond to incidents faster through intuitive Grafana dashboards.

## 🎯 Features

- Real-time monitoring of AWS WAF and VPC Flow Logs
- Custom Grafana dashboards for security visualization
- Automated alerting system for security incidents
- Integration with popular notification channels (Slack, PagerDuty, Email)
- Role-based access control (RBAC) for dashboard access
- Cost-optimized log querying and storage

## 🏗️ Architecture

![Architecture Overview](docs/images/architecture.png?v=2)

The project follows a serverless architecture leveraging AWS services:

1. **Log Collection**: AWS WAF and VPC Flow Logs are collected and stored in S3/CloudWatch
2. **Data Processing**: Logs are processed using Amazon Athena and CloudWatch Logs Insights
3. **Visualization**: Grafana dashboards provide real-time insights and alerts
4. **Notification**: Alerts are sent through configured notification channels

## 📊 Dashboard Examples

![Security Overview](docs/images/security-overview.png?v=2)
*Security Overview Dashboard showing key metrics and alerts*

![Traffic Analysis](docs/images/traffic-analysis.png?v=2)
*Network Traffic Analysis Dashboard with detailed flow logs visualization*

### Prerequisites

- AWS Account with appropriate permissions
- Grafana instance (self-hosted or AWS Managed Grafana)
- Basic understanding of AWS services and security concepts

### Step-by-Step Setup

1. **Enable Logging**
   ```bash
   # Use AWS CLI or follow the setup guide for enabling logs
   aws waf-regional put-logging-configuration --web-acl-id YOUR_WAF_ID --logging-configuration file://waf-logging.json
   aws ec2 create-flow-logs --resource-type VPC --resource-ids YOUR_VPC_ID --traffic-type ALL --log-destination-type s3
   ```

2. **Configure Data Sources**
   - Follow the instructions in [setup-guide.md](setup-guide.md) to configure Athena and CloudWatch data sources

3. **Import Dashboards**
   - Import the pre-built dashboards from the [grafana-dashboards](grafana-dashboards/) directory
   - Customize according to your needs

4. **Set Up Alerts**
   - Configure alerts using the templates in [alert-templates](alert-templates/)
   - Test notification channels

## Sample Dashboards

The repository includes several pre-built dashboards:

- Security Overview Dashboard
- WAF Analysis Dashboard
- VPC Flow Logs Dashboard
- Network Anomaly Detection Dashboard
- Executive Summary Dashboard

## Query Examples

### AWS WAF Logs Query
```sql
SELECT 
    COUNT(*) as blocked_requests,
    httpRequest.clientIp as source_ip,
    httpRequest.country as country
FROM waf_logs
WHERE action = 'BLOCK'
GROUP BY httpRequest.clientIp, httpRequest.country
ORDER BY blocked_requests DESC
LIMIT 10;
```

### VPC Flow Logs Query
```sql
SELECT 
    srcaddr,
    dstaddr,
    dstport,
    COUNT(*) as flow_count
FROM vpc_flow_logs
WHERE action = 'REJECT'
GROUP BY srcaddr, dstaddr, dstport
ORDER BY flow_count DESC
LIMIT 10;
```

## Maintenance and Optimization

- Regularly review and update AWS WAF rules
- Monitor Athena query costs and optimize as needed
- Update Grafana dashboards based on new security requirements
- Maintain proper access controls and authentication

## Additional Resources

- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/)
- [VPC Flow Logs Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [Grafana Documentation](https://grafana.com/docs/)
- [Security Best Practices](docs/security-best-practices.md)
