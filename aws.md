# AWS demo architecture — Covenant Radar

## §0 Decision

**DEMO ONLY — NOT THE PRODUCTION ARCHITECTURE IN `spec.md`.**

The AWS environment replicates the local-laptop demo. One Amazon EC2 Linux instance runs the complete application and its unchanged demo data:

```text
Demo users
  │ HTTPS :443
  ▼
EC2 instance (one machine, one Availability Zone)
  ├─ Nginx — TLS and reverse proxy
  ├─ FastAPI + Uvicorn — web UI and API
  ├─ SQLite — same seeded demo database file
  ├─ APScheduler — demo/background jobs
  ├─ var/documents — same demo documents
  └─ var/logs — local structured logs
       │
       └─ encrypted EBS volume and snapshots
```

There is no separate database, load balancer, container platform, object store, NAT gateway, or Kubernetes cluster. AWS replaces only the laptop: EC2 replaces the computer and encrypted EBS replaces its disk.

## §1 Purpose and scope

This architecture makes the **same demo data** available from the cloud. The release contains the same SQLite file, demo documents, seeded users, recorded model responses, and configuration that work locally. It is for demonstration, evaluation, and small controlled review sessions.

It does **not** change the production decision in `spec §§11 and 13`: production requires PostgreSQL 17. SQLite has one local database file and is unsuitable for production concurrent writes, customer records, regulated retention, or the production availability/recovery targets.

## §2 Compute and storage

Use one Amazon Linux 2023 EC2 instance in `ap-south-1` (Mumbai), with a `t3.small` as the default demo size. Increase only to `t3.medium` if OCR or the demo batch proves memory-constrained.

Attach one encrypted gp3 EBS volume. It holds the operating system, virtual environment, application release, SQLite database, documents, and logs.

| Path | Contents | Cloud equivalent |
|---|---|---|
| `var/demo/covenant-radar.sqlite3` | Immutable seeded SQLite demo database | EBS volume |
| `var/documents/` | Demo PDFs, images, and generated exports | EBS volume |
| `var/logs/` | Redacted demo logs | EBS volume |
| release package | Same code and locked dependencies as laptop | EC2 filesystem |

The instance is a single point of failure. This is acceptable for a demo, not a claim of high availability.

## §3 Data deployment and reset

Build one versioned demo bundle from the laptop repository:

```text
release/
  application code and lock file
  var/demo/covenant-radar.sqlite3
  var/documents/
  evaluation/cassettes/
  demo configuration
```

Copy the bundle to the EC2 instance before the service starts. Do not create a blank cloud database and do not run production migrations against the demo SQLite file.

For repeatable demonstrations, make the SQLite file and demo documents read-only to the application where practical. If a demonstration must allow edits, reset by stopping the service and restoring the versioned SQLite database and documents from the release bundle or a known-good EBS snapshot. Each demo therefore begins with identical data.

## §4 Request flow

1. A reviewer opens the EC2 HTTPS address.
2. Nginx terminates TLS and forwards the request to Uvicorn on `127.0.0.1`.
3. FastAPI authenticates the demo user, applies the application RBAC checks, and reads the local SQLite database and demo documents.
4. The response returns through Nginx over HTTPS.
5. Model features use recorded responses/cassettes by default, so demo data does not leave the instance and there is no model-provider cost.

## §5 Network and security

- Permit inbound TCP 443 only from the demonstrators’ and reviewers’ approved IP ranges.
- Do not expose SQLite, Uvicorn, SSH, or any database port publicly. Use AWS Systems Manager Session Manager for operator access if enabled; otherwise use a tightly restricted temporary SSH rule and remove it after setup.
- Bind Nginx publicly and Uvicorn only to loopback.
- Enable EBS encryption, IMDSv2, automatic security updates, a non-root application user, and a restrictive security group.
- Store private keys and application secrets in root-owned files outside the release directory. Never put them in the SQLite database, repository, AMI, logs, or screenshots.
- Use only synthetic/approved demo data. Do not upload customer banking data to this environment.

## §6 Backup and recovery

Take an encrypted EBS snapshot before each demonstration and after any intentional demo-data change. A snapshot lets an operator restore the exact SQLite file and documents to a replacement instance.

Recovery target for the demo is “restore before the next session.” It does not satisfy `spec §18`'s production RPO/RTO. Test restoration once before the first external demonstration.

## §7 Operations

Start the same application process used locally, behind Nginx:

```text
sudo systemctl start covenant-radar
```

Check `/health` before sharing the link. Watch instance CPU/memory, free disk, Nginx errors, application logs, and SQLite file permissions. Stop the service during a data reset:

```text
sudo systemctl stop covenant-radar
```

## §8 Cost boundary

Cost is bounded to one EC2 instance, one EBS volume, one public IPv4 address, and a small number of encrypted snapshots. No variable model usage is enabled. There are no load-balancer, RDS, NAT gateway, container, DNS-zone, or third-party charges in this design.

Use the account’s current `ap-south-1` EC2 and EBS prices before creating resources; public IPv4 addresses are charged per hour. Set a budget alert and tear down the instance and snapshots when the demo ends.

## §9 Production handoff

When this becomes a production deployment, replace only the local-demo data layer first:

```text
SQLite demo file  → PostgreSQL 17
demo local files  → production governed document store
single EC2 demo   → production capacity/recovery design
```

The FastAPI application, Nginx, application service layout, and most deployment flow can remain the same. Production must then meet every `spec.md` security, backup, retention, capacity, and acceptance requirement.
