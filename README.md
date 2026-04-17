# Linux Server Monitoring & Automation

A hands-on DevOps project built on AWS EC2 that automates the day-to-day maintenance work I was doing manually — cleaning up logs, keeping an eye on disk space, and making sure backups actually run. Three bash scripts, a few cron jobs, and a lot of trial and error on a live Ubuntu server.

---

## Background

When I started learning DevOps, I kept reading about automation but never actually sat down and built something. This project changed that. I spun up a free-tier EC2 instance, SSH'd in, and started writing scripts from scratch — breaking things, fixing them, and gradually understanding why certain Linux commands behave the way they do.

The goal wasn't to build something flashy. It was to understand how real servers get maintained, and to replace "I should probably do that manually" with something that just runs on its own.

---

## What This Does

**Log Cleanup** — Finds log files older than 7 days, compresses them, archives them, and eventually purges archives that are over 30 days old. Running this manually every week got old fast.

**Disk Monitor** — Checks every partition's usage every hour. If anything crosses 80%, it writes an alert. Saved me once when `/var` started filling up unexpectedly.

**Backup Script** — Takes a timestamped compressed snapshot of my scripts directory and key config files every night at 2 AM. Keeps the last 7 days, deletes the rest. Simple, but it works.

---

## Stack

| Layer | Choice |
|---|---|
| Cloud | AWS EC2 (t2.micro, Free Tier) |
| OS | Ubuntu 22.04 LTS |
| Language | Bash |
| Scheduler | Cron |
| Version Control | Git / GitHub |

---

## Project Structure

```
server-monitoring-automation/
│
├── scripts/
│   ├── log_cleanup.sh       # Compress and archive old logs
│   ├── disk_monitor.sh      # Check usage, alert at 80% threshold
│   └── backup.sh            # Daily snapshot with retention policy
│
└── README.md
```

---

## Setup

### 1. Launch an EC2 Instance

In the AWS Console, go to EC2 → Launch Instance and configure:

- **AMI:** Ubuntu Server 22.04 LTS (Free Tier eligible)
- **Instance type:** t2.micro
- **Key pair:** Create a new one and download the `.pem` file — keep it safe
- **Security Group:** Allow SSH on port 22, restricted to your IP
- **Storage:** 8 GB is fine for this project

### 2. Connect via SSH

```bash
# Mac / Linux
chmod 400 ~/Downloads/devops-key.pem
ssh -i ~/Downloads/devops-key.pem ubuntu@<YOUR-EC2-PUBLIC-IP>

# Windows (PowerShell)
icacls "C:\path\to\devops-key.pem" /inheritance:r /grant:r "%USERNAME%:(R)"
ssh -i "C:\path\to\devops-key.pem" ubuntu@<YOUR-EC2-PUBLIC-IP>
```

Your public IP is in the EC2 console under **Instances → Public IPv4 address**.

### 3. Prepare the Server

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git htop tree unzip
sudo hostnamectl set-hostname devops-server
```

### 4. Clone the Repository

```bash
git clone https://github.com/KhalilAhmadPK/server-monitoring-automation.git
cd server-monitoring-automation
chmod +x scripts/*.sh
```

### 5. Test Each Script Manually

Before setting up cron, run each script by hand to make sure it works on your machine:

```bash
bash scripts/disk_monitor.sh
bash scripts/backup.sh
bash scripts/log_cleanup.sh
```

Check the output and the log files in `~/scripts/` to confirm everything ran correctly.

### 6. Set Up Cron Jobs

```bash
crontab -e
```
Add these lines:

```bash
# Disk check every hour
0 * * * * /home/$USER/scripts/disk_monitor.sh >> /home/$USER/scripts/cron.log 2>&1

# Backup every night at 2 AM
0 2 * * * /home/$USER/scripts/backup.sh >> /home/$USER/scripts/cron.log 2>&1

# Log cleanup every Sunday at 3 AM
0 3 * * 0 /home/$USER/scripts/log_cleanup.sh >> /home/$USER/scripts/cron.log 2>&1
```

Verify with `crontab -l` that the jobs are registered.

---

## Scripts in Detail

### `log_cleanup.sh`

Scans `/var/log` for `.log` files modified more than 7 days ago, compresses them with gzip, and moves them to `~/log_archives/`. Archives older than 30 days are deleted automatically. Every run appends a summary to `cleanup_report.log`.

```bash
bash scripts/log_cleanup.sh
# Output: cleanup_report.log
```

### `disk_monitor.sh`

Uses `df -h` to check all mounted partitions. If any partition's usage percentage is at or above the `THRESHOLD` variable (default: 80), it logs an alert to `disk_alerts.log`. All results are written to `disk_report.log`.

```bash
bash scripts/disk_monitor.sh
# Output: disk_report.log, disk_alerts.log (if threshold crossed)
```

To change the alert threshold, edit the `THRESHOLD` variable at the top of the script:

```bash
THRESHOLD=80   # change to whatever makes sense for your server
```

### `backup.sh`

Creates a `.tar.gz` archive named with the current date and time, containing everything in `~/scripts/` and `/etc/crontab`. Backups go into `~/backups/`. The script keeps the last 7 days and removes anything older. A success or failure message is appended to `backup_report.log` after each run.

```bash
bash scripts/backup.sh
# Output: ~/backups/backup_YYYY-MM-DD_HH-MM.tar.gz, backup_report.log
```

---

## Cron Schedule Reference

| Cron Expression | Script | When It Runs |
|---|---|---|
| `0 * * * *` | disk_monitor.sh | Every hour, on the hour |
| `0 2 * * *` | backup.sh | Every day at 2:00 AM |
| `0 3 * * 0` | log_cleanup.sh | Every Sunday at 3:00 AM |

**Quick cron syntax reminder:**

```
* * * * *
│ │ │ │ └─ Day of week  (0 = Sunday)
│ │ │ └─── Month        (1–12)
│ │ └───── Day of month (1–31)
│ └─────── Hour         (0–23)
└───────── Minute       (0–59)
```

---

## Log Files

All scripts write their output to log files inside `~/scripts/`:

| File | Written By | Contents |
|---|---|---|
| `cleanup_report.log` | log_cleanup.sh | Compression and archive activity |
| `disk_report.log` | disk_monitor.sh | Per-partition usage per run |
| `disk_alerts.log` | disk_monitor.sh | Alerts only (threshold crossed) |
| `backup_report.log` | backup.sh | Backup success/failure per run |
| `cron.log` | All (via cron) | Combined stdout from scheduled runs |

---

## Troubleshooting

**Permission denied when running a script**
```bash
chmod +x scripts/your-script.sh
```

**Cron jobs not running**
Check if cron is active on the server:
```bash
sudo systemctl status cron
sudo systemctl start cron
```

Then check `cron.log` to see if there are any errors from the last scheduled run.

**SSH connection refused**
- Check that port 22 is open in your EC2 Security Group
- Make sure you're using the correct public IP (it changes on restart unless you assign an Elastic IP)
- Confirm the key file path is correct

**Disk alert triggering immediately**
The default threshold is 80%. If your root partition is already above that, lower the threshold to test first and adjust from there.

---

## What I Learned

Honestly, the hardest part wasn't writing the scripts — it was debugging them. Bash error messages aren't always helpful, and the difference between a script that works interactively and one that runs correctly under cron (with a stripped-down environment) cost me a couple of hours.

A few things that stuck:

- Always use full absolute paths inside scripts, especially when cron runs them
- `2>&1` redirects stderr to stdout — without it, cron errors disappear silently
- `chmod +x` isn't optional even if you're calling the script with `bash`
- `crontab -l` before closing the editor. Just always do this.

This is the first project in a longer DevOps learning roadmap I'm working through, covering Docker, CI/CD, AWS services, Kubernetes, and Terraform over the next few months.

---

## Author

Built by someone who got tired of doing server maintenance manually.

**[Khalil Ahmad]** — [GitHub](https://github.com/KhalilAhmadPK) · [LinkedIn](https://linkedin.com/in/)

---

*Part of a 30-project DevOps learning roadmap.*
