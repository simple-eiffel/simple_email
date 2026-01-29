# AlertStream - System Monitoring Email Gateway

## Executive Summary

AlertStream is a CLI-based email gateway designed for DevOps and SRE teams to receive system alerts via email without relying on expensive third-party notification services like PagerDuty or Opsgenie. It acts as a smart intermediary between monitoring systems and email delivery, providing intelligent alert aggregation, deduplication, digest scheduling, and rule-based routing.

The tool accepts events via stdin, file input, or a simple HTTP endpoint (future), applies configurable rules to determine routing and severity, and delivers notifications via SMTP. Its killer feature is intelligent alert fatigue reduction through configurable deduplication windows, digest aggregation, and escalation rules.

AlertStream fills a significant gap in the self-hosted monitoring stack. While tools like Prometheus, Grafana, and custom scripts can detect issues, getting those alerts to the right people at the right time - without overwhelming them - requires sophisticated notification logic that AlertStream provides.

## Problem Statement

**The problem:** DevOps teams receive too many alerts, leading to alert fatigue. Important issues get lost in noise. Commercial notification services (PagerDuty at $21/user/month, Opsgenie at $9/user/month) add significant cost for small-to-medium teams.

**Current solutions:**
- **PagerDuty/Opsgenie:** Comprehensive but expensive ($252-500/year per user)
- **Direct SMTP from monitoring:** No deduplication, floods inboxes
- **Slack/Teams webhooks:** Notifications get buried, no escalation
- **Custom scripts:** Maintenance burden, no standardization

**Our approach:** A dedicated CLI tool that:
- Receives alerts from any source (stdin, file, webhook)
- Applies rule-based routing and severity classification
- Deduplicates within configurable time windows
- Aggregates related alerts into digests
- Sends via standard SMTP (your infrastructure)
- Logs everything for audit/debugging

## Target Users

| User Type | Description | Key Needs |
|-----------|-------------|-----------|
| **Primary: DevOps Engineer** | Manages infrastructure monitoring | Alert routing, deduplication, escalation |
| **Primary: SRE** | Maintains service reliability | Alert aggregation, severity classification |
| **Secondary: IT Administrator** | Manages enterprise systems | On-prem solution, audit logs |
| **Secondary: Developer** | Monitors application health | Simple integration, actionable alerts |

## Value Proposition

**For** DevOps and SRE teams
**Who** need reliable alert delivery without alert fatigue
**This app** provides intelligent alert aggregation and email delivery
**Unlike** expensive SaaS notification services
**We** offer self-hosted, zero per-user cost, full data control

## Revenue Model

| Model | Description | Price Point |
|-------|-------------|-------------|
| **Starter** | Open source core, 10 rules, basic alerts | Free |
| **Team** | Unlimited rules, digest mode, deduplication | $199/year |
| **Enterprise** | Multi-system, escalation chains, audit logs, SLA | $799/year |

**Additional revenue:**
- Integration consulting: Custom rule development ($150/hour)
- Training: AlertStream admin training ($300/seat)
- Support: 24/7 support add-on ($499/year)

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Alert delivery latency | <5 seconds | Time from event to email sent |
| Deduplication effectiveness | >50% reduction | Alerts suppressed / raw alerts |
| Digest aggregation ratio | >10:1 | Events per digest email |
| False positive rate | <1% | Misrouted alerts / total alerts |
| System uptime | 99.9% | Available time / total time |

## Competitive Comparison

| Feature | AlertStream | PagerDuty | Opsgenie | Custom Scripts |
|---------|-------------|-----------|----------|----------------|
| Monthly cost (10 users) | $0-66 | $210+ | $90+ | $0 |
| Self-hosted | Yes | No | No | Yes |
| Alert deduplication | Yes | Yes | Yes | Manual |
| Digest aggregation | Yes | Yes | Yes | Manual |
| Escalation chains | Enterprise | Yes | Yes | Manual |
| On-call scheduling | No* | Yes | Yes | No |
| Mobile app | No | Yes | Yes | No |
| Audit logs | Yes | Yes | Yes | Manual |
| SMTP delivery | Yes | Yes | Yes | Yes |
| Custom integrations | Stdin/file | API | API | Custom |

*On-call scheduling is out of scope - AlertStream focuses on notification delivery, not scheduling.

## Use Cases

### Use Case 1: Prometheus Alert Routing
```bash
# Prometheus alertmanager webhook receiver
curl -X POST -d @alert.json http://localhost:9095/webhook | alertstream route
```

### Use Case 2: Log File Monitoring
```bash
# Tail application log for errors
tail -f /var/log/app.log | grep ERROR | alertstream ingest --source app-errors
```

### Use Case 3: Batch Job Failure Notification
```bash
# CI/CD pipeline failure
echo '{"event":"build_failed","job":"deploy-prod","exit_code":1}' | alertstream send --rule critical
```

### Use Case 4: Scheduled Health Check Digest
```bash
# Cron job: Send hourly digest of accumulated alerts
0 * * * * alertstream digest --period 1h --recipients oncall@company.com
```
