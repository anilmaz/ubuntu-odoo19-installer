# ubuntu-odoo19-installer

[![Odoo Version](https://img.shields.shields.io/badge/Odoo-19.0-875A7B?logo=odoo&logoColor=white)](https://www.odoo.com)
[![OS Compatibility](https://img.shields.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Database](https://img.shields.shields.io/badge/PostgreSQL-17-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![License: GPL v3](https://img.shields.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

A pair of robust, idempotent, and highly interactive shell scripts engineered to deploy and completely tear down Odoo 19 environments on Ubuntu 24.04 LTS (Noble Numbat). Designed with a focus on multicloud data workloads, strict data preservation gates, and real-time human lifecycle performance metrics.

---


🚀 Key Features
📦 Master Installer (install_odoo19.sh)
Ubuntu 24.04 LTS Compatibility: Automatically manages modern package layout modifications, such as the libaio1t64 shift and explicit version-locked python3.12-venv abstractions.

Pre-Flight Environment Sniffing: Checks the host machine for existing directory mappings, matching system daemon users, and port usage before writing configurations to prevent namespace collisions.

Interactive Configuration Matrix: Empowers the operator to choose custom port bindings, dedicated PostgreSQL usernames, and secure passwords.

High-Privilege Security Injector: Forces LOGIN SUPERUSER CREATEDB roles right out of the gate to ensure background application threads can manipulate schema tables natively without permission drops during manual web-based restorations.

Enterprise Driver Injection: Automatically maps and injects critical data engineering packages (pysftp, pandas, cx-oracle==6.1, and oracledb) into the isolated virtual environment runtime sheet.

Automated End-Point Discovery: Dynamically extracts the host identity and active outwards-facing IPv4 network addresses, presenting direct browser connection URLs at the completion banner.

🗑️ Smart Uninstaller (uninstall_odoo19.sh)
Odoo-Compatible ZIP Backup Engine: Automatically packages database text dumps (dump.sql), native binary attachments (filestore/), and an explicit metadata tracking manifest (manifest.json) into a single unified zip container that passes Odoo Web UI Verification checks (/web/database/manager).

Orphan Filestore Rescue Guard: If the database is missing or was dropped prior to execution, the script automatically flags the state, pauses execution, and opens an interactive prompt allowing you to pack up or manually protect the unlinked disk filestore before structural paths are destroyed.

Forceful Disconnect Purge Engine: Severs active web sockets and connection pools hanging onto the target schema inside PostgreSQL via backend process termination queries (pg_terminate_backend) to guarantee complete database drops.

🎨 Visual & Performance Frameworks
Rainbow Progress Matrix: Custom, color-coded terminal horizontal arrays that provide fluid visibility across installation milestones.

Human-Scale Performance Logging: Utilizes precision epoch timestamps to log actual wall-clock runtimes in a clean Xm Ys presentation layout accompanied by matching calendar date markers.

🛠️ Usage Instructions
Clone this repository to your target Ubuntu 24.04 server, jump inside the folder namespace, and grant absolute execution rights to the scripts:

Bash
git clone [https://github.com/anilmaz/ubuntu-odoo19-installer.git](https://github.com/anilmaz/ubuntu-odoo19-installer.git)
cd ubuntu-odoo19-installer
chmod +x install_odoo19.sh uninstall_odoo19.sh
Running the Installer
Execute the file with root capabilities using sudo:

Bash
sudo ./install_odoo19.sh
Running the Uninstaller
To safely pull an enterprise zip backup and wipe all physical structures cleanly:

Bash
sudo ./uninstall_odoo19.sh
📂 Backup Directory Layout
When the uninstaller processes an active instance, all critical application data assets are packed up safely from their default system locations and nested within your home user space under:

Plaintext
~/migration_backups/
└── odoo_backup_odoo19_YYYYMMDD_HHMMSS.zip
    ├── dump.sql             <-- Complete PostgreSQL relational schema dump
    ├── manifest.json        <-- Odoo web manager verification descriptor
    └── filestore/           <-- Binary attachment arrays mapped to record IDs
For issues, optimization pull requests, or explicit enterprise implementation inquiries, please get in touch via GitHub.

## ✒️ Author & Copyright Information

* **Author:** Anil Mahadev
* **Email:** [anilmaz2024@gmail.com](mailto:anilmaz2024@gmail.com)
* **Website:** [anilmahadev.odoo.com](https://anilmahadev.odoo.com)
* **GitHub Repository:** [https://github.com/anilmaz](https://github.com/anilmaz)

```text
Copyright (c) 2026 Anil Mahadev. All Rights Reserved.
Licensed under the GNU GPLv3 Open Source Framework.

CRITICAL NOTICE: Unauthorized copying, modification, distribution, or re-use 
of this orchestration architecture layer via any medium is strictly prohibited. 
You MUST contact the author explicitly at the email or GitHub profile listed above 
to request permission before re-using or publishing any part of these scripts.
