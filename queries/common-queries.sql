-- WAF Logs Analysis Queries

-- Top 10 blocked IP addresses in the last 24 hours
SELECT 
    httpRequest.clientIp as source_ip,
    COUNT(*) as blocked_requests,
    MAX(from_unixtime(timestamp/1000)) as last_seen
FROM 
    waf_logs
WHERE 
    action = 'BLOCK'
    AND from_unixtime(timestamp/1000) >= date_add('hour', -24, current_timestamp)
GROUP BY 
    httpRequest.clientIp
ORDER BY 
    blocked_requests DESC
LIMIT 10;

-- Blocked requests by rule ID
SELECT 
    terminatingRuleId,
    COUNT(*) as block_count
FROM 
    waf_logs
WHERE 
    action = 'BLOCK'
    AND from_unixtime(timestamp/1000) >= date_add('hour', -24, current_timestamp)
GROUP BY 
    terminatingRuleId
ORDER BY 
    block_count DESC;

-- Geographic distribution of blocked requests
SELECT 
    httpRequest.country,
    COUNT(*) as request_count
FROM 
    waf_logs
WHERE 
    action = 'BLOCK'
    AND from_unixtime(timestamp/1000) >= date_add('hour', -24, current_timestamp)
GROUP BY 
    httpRequest.country
ORDER BY 
    request_count DESC;

-- VPC Flow Logs Analysis Queries

-- Top source IPs with rejected connections
SELECT 
    srcaddr,
    COUNT(*) as reject_count,
    array_agg(DISTINCT dstport) as targeted_ports
FROM 
    vpc_flow_logs
WHERE 
    action = 'REJECT'
    AND from_unixtime(start) >= date_add('hour', -24, current_timestamp)
GROUP BY 
    srcaddr
ORDER BY 
    reject_count DESC
LIMIT 20;

-- Port scanning detection (multiple ports targeted)
SELECT 
    srcaddr,
    COUNT(DISTINCT dstport) as unique_ports,
    COUNT(*) as total_attempts
FROM 
    vpc_flow_logs
WHERE 
    action = 'REJECT'
    AND from_unixtime(start) >= date_add('hour', -1, current_timestamp)
GROUP BY 
    srcaddr
HAVING 
    COUNT(DISTINCT dstport) > 10
ORDER BY 
    unique_ports DESC;

-- Traffic volume by protocol
SELECT 
    CASE protocol
        WHEN 6 THEN 'TCP'
        WHEN 17 THEN 'UDP'
        WHEN 1 THEN 'ICMP'
        ELSE CAST(protocol AS VARCHAR)
    END as protocol_name,
    action,
    COUNT(*) as flow_count,
    SUM(bytes) as total_bytes
FROM 
    vpc_flow_logs
WHERE 
    from_unixtime(start) >= date_add('hour', -24, current_timestamp)
GROUP BY 
    protocol,
    action
ORDER BY 
    flow_count DESC;

-- Potential DDoS detection (high traffic volume)
SELECT 
    dstaddr,
    COUNT(*) as connection_count,
    SUM(bytes) as total_bytes,
    COUNT(DISTINCT srcaddr) as unique_sources
FROM 
    vpc_flow_logs
WHERE 
    from_unixtime(start) >= date_add('minute', -5, current_timestamp)
GROUP BY 
    dstaddr
HAVING 
    COUNT(*) > 1000
ORDER BY 
    connection_count DESC;

-- Suspicious outbound connections (high volume to single destination)
SELECT 
    srcaddr,
    dstaddr,
    dstport,
    COUNT(*) as connection_count,
    SUM(bytes) as total_bytes
FROM 
    vpc_flow_logs
WHERE 
    action = 'ACCEPT'
    AND from_unixtime(start) >= date_add('hour', -1, current_timestamp)
GROUP BY 
    srcaddr,
    dstaddr,
    dstport
HAVING 
    COUNT(*) > 100
ORDER BY 
    total_bytes DESC; 