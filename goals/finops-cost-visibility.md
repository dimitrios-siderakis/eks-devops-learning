# FinOps & Cost Visibility Objective

**Status:** Active  
**Review Date:** 31 Aug 2026  
**End Date:** 31 Dec 2026  

---

## Objective Summary

Cloud and data platform costs (AWS, Snowflake) are growing without sufficient visibility or accountability. Without structured cost intelligence, we can't forecast, optimize, or defend spend decisions to the business. By embedding FinOps discipline into our team practices, we reduce waste, enable informed trade-offs, and position Data DevOps as a trusted partner to Finance and Engineering leadership.

---

## Task Breakdown (1/3 complete)

### 1. ✅ Snowflake: Create a cost related report/dashboard for Snowflake

**Status:** COMPLETED  
**Details:**
- Cost-related report/dashboard for Snowflake created and accepted complete.

---

### 2. [ ] AWS: Create a cost dashboard or report for AWS services able to pick up abnormalities

**Status:** NOT STARTED  
**Target Date:** 31 Aug 2026  
**Key Topics:**
- AWS Cost Explorer — service-level and tag-level breakdown
- AWS Cost Anomaly Detection — threshold-based alerting on unexpected spend
- Cost allocation tags — mapping spend to teams, environments, and workloads
- Dashboard delivery (QuickSight, Grafana, or exported report)

**Sub-items:**
- [ ] **Tagging strategy & enforcement** — define a consistent tag schema (`team`, `env`, `workload`) and enforce it via AWS Config or SCPs; prerequisite for meaningful per-team cost breakdown
- [ ] **AWS Budgets & alerts** — set proactive spend thresholds per service/team so abnormalities are caught before the dashboard review cycle

---

### 3. [ ] AWS: Find a way to pick up unused AWS resources and clean them out

**Status:** NOT STARTED  
**Target Date:** 31 Dec 2026  
**Key Topics:**
- Identifying idle/unattached resources: unattached EBS volumes, unused Elastic IPs, idle load balancers, stopped EC2 instances
- AWS Trusted Advisor and Compute Optimizer recommendations
- Automated cleanup approach (Lambda + EventBridge or AWS Config rules)
- Safe deletion policy: tagging, dry-run mode, approval gate before destruction
