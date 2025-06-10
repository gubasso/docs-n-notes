# DevOps: Operational Responsibilities for Application Infrastructure

> **Purpose**: This checklist identifies every ongoing duty required to deploy, operate, and harden any production application server. Use it as the master roadmap; link detailed runbooks for each task.

---

## 1 · Setup & Provisioning

* [ ] Choose hosting platform (cloud VM, container platform, on‑prem bare‑metal)
* [ ] Harden base OS (minimal packages, firewall, SSH hardening, time syncing)
* [ ] Install runtime prerequisites (container engine, language runtimes, package managers)
* [ ] Deploy application artifacts (containers, binaries, or code)
* [ ] Configure ingress (reverse proxy, load balancer) and enforce HTTPS (TLS certs, HSTS)
* [ ] Store bootstrap secrets and credentials in a secure vault
* [ ] Commit infrastructure‑as‑code and configuration to version control

## 2 · Baseline Operations

* [ ] Schedule and apply application and dependency updates
* [ ] Enable automatic restarts and health‑check probes
* [ ] Validate service functionality after every change (smoke tests)
* [ ] Track uptime objectives and error budgets

## 3 · Security Maintenance

* [ ] Apply OS and middleware patches on a regular cadence
* [ ] Conduct vulnerability scans; remediate findings promptly
* [ ] Automate TLS certificate issuance and renewal
* [ ] Rotate secrets, keys, and tokens per policy
* [ ] Enforce least‑privilege access and periodic permission reviews
* [ ] Monitor for intrusion indicators and anomalous activity

## 4 · Logging & Monitoring

* [ ] Aggregate system and application logs in a central platform
* [ ] Define actionable alerts for CPU, memory, disk, latency, error rates, auth failures
* [ ] Tune alert thresholds to balance responsiveness and noise
* [ ] Retain logs according to compliance and audit requirements

## 5 · Backup & Disaster Recovery

* [ ] Define backup scope: data stores, application files, configuration, certificates
* [ ] Automate encrypted, off‑site backups on a fixed schedule
* [ ] Perform routine restore tests to verify backup integrity
* [ ] Document recovery time (RTO) and recovery point (RPO) objectives
* [ ] Conduct disaster‑recovery drills and refine plans from lessons learned

## 6 · Performance & Capacity Management

* [ ] Monitor application latency, query times, and resource utilization
* [ ] Tune application configuration, runtime parameters, and database indexes
* [ ] Forecast growth in load and storage requirements
* [ ] Plan vertical upgrades or horizontal scaling (additional nodes, load balancers)

## 7 · Documentation & Compliance

* [ ] Maintain up‑to‑date runbooks for deployment, rollback, and failover
* [ ] Preserve audit logs of administrative actions for governance
* [ ] Keep architecture diagrams, network maps, and change history current
* [ ] Align data retention, encryption, and access controls with regulatory standards

## 8 · Review & Continuous Improvement

* [ ] Review incidents, metrics, and capacity monthly
* [ ] Conduct post‑mortems and integrate learnings into processes
* [ ] Schedule regular security assessments and penetration tests
* [ ] Automate repetitive tasks to reduce operational toil

---

**Next Steps**

1. Assign owners and review dates to each checklist item.
2. Develop detailed runbooks for each responsibility.
3. Automate wherever possible (patching, backups, scanning, alerting).
