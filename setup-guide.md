# SOC Dashboard Setup Guide

This guide provides detailed instructions for setting up the AWS SOC Dashboard project.

## Table of Contents
- [Prerequisites](#prerequisites)
- [AWS Configuration](#aws-configuration)
- [Grafana Setup](#grafana-setup)
- [Dashboard Import](#dashboard-import)
- [Alert Configuration](#alert-configuration)
- [Troubleshooting](#troubleshooting)

## Prerequisites

1. **AWS Account Setup**
   - Active AWS account with administrative access
   - AWS CLI installed and configured
   - Appropriate IAM roles and permissions

2. **Grafana Requirements**
   - Grafana 9.0+ installed
   - AWS plugins installed:
     - AWS CloudWatch plugin
     - AWS Athena plugin

## AWS Configuration

### 1. Enable AWS WAF Logging

1. Create an S3 bucket for WAF logs:
```bash
aws s3 mb s3://your-waf-logs-bucket --region your-region
```

2. Create WAF logging configuration:
```json
{
    "LoggingConfiguration": {
        "ResourceArn": "arn:aws:s3:::your-waf-logs-bucket",
        "LogDestinationConfigs": [
            "arn:aws:s3:::your-waf-logs-bucket/waf-logs/"
        ]
    }
}
```

3. Enable WAF logging:
```bash
aws waf-regional put-logging-configuration --web-acl-id YOUR_WAF_ID --logging-configuration file://waf-logging.json
```

### 2. Enable VPC Flow Logs

1. Create an S3 bucket for VPC Flow Logs:
```bash
aws s3 mb s3://your-vpc-flow-logs-bucket --region your-region
```

2. Enable Flow Logs:
```bash
aws ec2 create-flow-logs \
    --resource-type VPC \
    --resource-ids vpc-xxxxxxxx \
    --traffic-type ALL \
    --log-destination-type s3 \
    --log-destination arn:aws:s3:::your-vpc-flow-logs-bucket/flow-logs/
```

### 3. Set Up Athena

1. Create an Athena database:
```sql
CREATE DATABASE security_logs;
```

2. Create WAF logs table:
```sql
CREATE EXTERNAL TABLE waf_logs (
    timestamp bigint,
    formatVersion int,
    webaclId string,
    terminatingRuleId string,
    action string,
    httpSourceName string,
    httpSourceId string,
    ruleGroupList array<struct<ruleGroupId:string,terminatingRule:struct<ruleId:string,action:string,ruleMatchDetails:array<struct<conditionType:string,sensitivityLevel:string,location:string,matchedData:array<string>>>>,nonTerminatingMatchingRules:array<struct<ruleId:string,action:string,ruleMatchDetails:array<struct<conditionType:string,sensitivityLevel:string,location:string,matchedData:array<string>>>>>,excludedRules:array<struct<exclusionType:string,ruleId:string>>>>,
    rateBasedRuleList array<struct<rateBasedRuleId:string,limitKey:string,maxRateAllowed:int>>,
    nonTerminatingMatchingRules array<struct<ruleId:string,action:string,ruleMatchDetails:array<struct<conditionType:string,sensitivityLevel:string,location:string,matchedData:array<string>>>>>,
    httpRequest struct<clientIp:string,country:string,headers:array<struct<name:string,value:string>>,uri:string,args:string,httpVersion:string,httpMethod:string,requestId:string>
)
PARTITIONED BY (year string, month string, day string)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://your-waf-logs-bucket/waf-logs/';
```

3. Create VPC Flow Logs table:
```sql
CREATE EXTERNAL TABLE vpc_flow_logs (
    version int,
    account_id string,
    interface_id string,
    srcaddr string,
    dstaddr string,
    srcport int,
    dstport int,
    protocol int,
    packets int,
    bytes bigint,
    start bigint,
    end bigint,
    action string,
    log_status string
)
PARTITIONED BY (date string)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ' '
LOCATION 's3://your-vpc-flow-logs-bucket/flow-logs/';
```

## Grafana Setup

### 1. Install Required Plugins

```bash
grafana-cli plugins install grafana-athena-datasource
grafana-cli plugins install grafana-cloudwatch-datasource
systemctl restart grafana-server
```

### 2. Configure Data Sources

1. **AWS Athena Data Source**
   - Name: AWS-Athena
   - Auth Provider: AWS SDK Default
   - Default Region: your-region
   - Database: security_logs
   - Workgroup: primary
   - Output Location: s3://your-athena-results-bucket/

2. **CloudWatch Data Source**
   - Name: AWS-CloudWatch
   - Auth Provider: AWS SDK Default
   - Default Region: your-region

## Dashboard Import

1. Navigate to Grafana → Dashboards → Import
2. Import each JSON file from the `grafana-dashboards` directory
3. Select the appropriate data sources for each dashboard
4. Save and test the dashboards

## Alert Configuration

### 1. Set Up Notification Channels

1. **Slack Integration**
   ```bash
   # Create Slack webhook
   curl -X POST -H 'Content-type: application/json' \
   --data '{"text":"SOC Dashboard Alert Test"}' \
   YOUR_SLACK_WEBHOOK_URL
   ```

2. **Email Notifications**
   - Configure SMTP settings in Grafana
   - Test email delivery

### 2. Configure Alert Rules

1. WAF Blocked Requests Alert:
   - Metric: Count of blocked requests
   - Threshold: > 100 in 5 minutes
   - Severity: High

2. VPC Flow Logs Alert:
   - Metric: Count of REJECT actions
   - Threshold: > 50 in 5 minutes
   - Severity: Medium

## Troubleshooting

### Common Issues

1. **Data Not Appearing in Dashboards**
   - Verify log delivery to S3
   - Check Athena table partitions
   - Validate IAM permissions

2. **Alert Notifications Not Working**
   - Test notification channels
   - Check network connectivity
   - Verify webhook URLs

3. **Performance Issues**
   - Optimize Athena queries
   - Add appropriate partitioning
   - Review dashboard refresh intervals

### Support Resources

- AWS WAF Documentation
- Grafana Documentation
- Project GitHub Issues
- Community Forums 