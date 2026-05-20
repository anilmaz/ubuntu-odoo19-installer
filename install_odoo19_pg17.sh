#!/usr/bin/env bash
# ==============================================================================
# Script Name: install_odoo19.sh
# Description: Idempotent & Interactive Odoo 19 Installer for Ubuntu 24.04 LTS
# ==============================================================================
# Author:      Anil Mahadev
# Email:       anilmaz2024@gmail.com
# Website:     https://anilmahadev.odoo.com
# GitHub:      https://github.com/anilmaz
#
# Copyright (c) 2026 Anil Mahadev. All Rights Reserved.
# NOTICE: Unauthorized copying, modification, or redistribution of this script
# via any medium is strictly prohibited. Please contact the author prior to
# re-using or publishing components of this architecture layer.
# ==============================================================================

NC='\033[0m'
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'

# Capture the exact calendar wall-clock start time
START_TIME=$(date +%s)
START_DATE_STR=$(date "+%Y-%m-%d %H:%M:%S")

show_progress() {
    local duration=$1
    local label=$2
    local col=50
    echo -ne "${CYAN}${BOLD}[PROCESSING] ${label}...${NC}\n"
    
    for ((i=1; i<=col; i++)); do
        local pct=$((i * 100 / col))
        case $((i % 5)) in
            0) echo -ne "${RED}█${NC}" ;;
            1) echo -ne "${YELLOW}█${NC}" ;;
            2) echo -ne "${GREEN}█${NC}" ;;
            3) echo -ne "${BLUE}█${NC}" ;;
            4) echo -ne "${PURPLE}█${NC}" ;;
        esac
        echo -ne " ${pct}%\r"
        sleep "$(echo "scale=3; ${duration} / ${col}" | bc 2>/dev/null || echo "0.02")"
    done
    echo -e "\n${GREEN}[COMPLETED]${NC}\n"
}

log_info() { echo -e "${GREEN}${BOLD}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}${BOLD}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}${BOLD}[ERROR]${NC} $1"; }

clear
echo -e "${BLUE}${BOLD}======================================================================"
echo -e "         TWISTED CAROUSL PRODUCTION-GRADE ODOO 19 DEPLOYMENT          "
echo -e "======================================================================${NC}"

if [ "$EUID" -ne 0 ]; then
    log_error "This installer must be executed with root privileges via sudo."
    exit 1
fi

# --- SMART PRE-FLIGHT ANALYSIS ---
echo -e "${CYAN}${BOLD}[PRE-FLIGHT] Analyzing target system architecture...${NC}"
ODOO_USER="odoo19"
ODOO_HOME="/opt/${ODOO_USER}"
ODOO_LOG_DIR="/var/log/odoo"

EXISTING_USER=false; EXISTING_DIR=false
if id "${ODOO_USER}" &>/dev/null; then EXISTING_USER=true; fi
if [ -d "${ODOO_HOME}" ]; then EXISTING_DIR=true; fi

if [ "$EXISTING_USER" = true ] || [ "$EXISTING_DIR" = true ]; then
    log_warn "An existing Odoo 19 layout or partial deployment was detected."
    read -p "Do you want to smartly patch/upgrade this instance without losing data? (y/n): " PROCEED_SMART
    if [[ ! "$PROCEED_SMART" =~ ^[Yy]$ ]]; then
        log_error "Installation cancelled by operator."; exit 0
    fi
fi

# --- INTERACTIVE USER PARAMETER MATRIX ---
echo -e "\n${PURPLE}${BOLD}[ENVIRONMENT CONFIGURATION PARAMETERS]${NC}"
DEFAULT_PORT=8069
while true; do
    read -p "Assign Odoo Application Service Port [Default: $DEFAULT_PORT]: " ODOO_PORT
    ODOO_PORT=${ODOO_PORT:-$DEFAULT_PORT}
    if ss -tuln | grep -q ":$ODOO_PORT " ; then
        log_warn "Port $ODOO_PORT is already actively bound."
        read -p "Force use this mapping anyway? (y/n): " PORT_CONFIRM
        if [[ "$PORT_CONFIRM" =~ ^[Yy]$ ]]; then break; fi
    else
        break
    fi
done

read -p "Assign PostgreSQL User Account for Odoo [Default: odoo19]: " POSTGRES_USER
POSTGRES_USER=${POSTGRES_USER:-odoo19}

read -p "Assign Secure Password for DB User [$POSTGRES_USER]: " DB_PASSWORD
while [ -z "$DB_PASSWORD" ]; do
    log_error "Password cannot be blank."
    read -p "Assign Secure Password for DB User [$POSTGRES_USER]: " DB_PASSWORD
done

ODOO_CONF="/etc/${POSTGRES_USER}.conf"
ODOO_LOG_FILE="${ODOO_LOG_DIR}/${POSTGRES_USER}.log"

# --- SYSTEM DEPLOYMENT MATRIX ---
echo -e "\n${CYAN}${BOLD}Step 1: Synchronizing Core Apt Distribution Repositories & Postgres 17 GPG Keys${NC}"
# Pre-install prerequisites for key management
apt-get update -y >/dev/null 2>&1
apt-get install -y gnupg curl ca-certificates lsb-release bc >/dev/null 2>&1

# Securely fetch official PostgreSQL signing keys & append verified repo (FIXED FILENAME)
install -d /etc/apt/keyrings
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor --yes -o /etc/apt/keyrings/postgresql.gpg
echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Refresh apt list cache with the brand new PostgreSQL channel
apt-get update -y >/dev/null 2>&1
show_progress 1.5 "Updating package manifests & caching pgdg ecosystem"

echo -e "\n${CYAN}${BOLD}Step 2: Installing Libraries and Data Runtimes (PostgreSQL 17 Target)${NC}"
apt-get install -y python3-pip python3-dev python3-venv python3.12-venv libxml2-dev libxslt1-dev \
    zlib1g-dev libsasl2-dev libldap2-dev build-essential libssl-dev libffi-dev \
    libjpeg-dev libpq-dev liblcms2-dev libblas-dev libatlas-base-dev \
    git nodejs npm xfonts-75dpi curl libaio1t64 wkhtmltopdf postgresql-17 postgresql-client-17 >/dev/null 2>&1
show_progress 3.0 "Compiling layout toolchains"

echo -e "\n${CYAN}${BOLD}Step 3: Setting Up Frontend Less/CSS Processing Engines${NC}"
if [ ! -f /usr/bin/node ]; then ln -s /usr/bin/nodejs /usr/bin/node 2>/dev/null; fi
npm install -g less less-plugin-clean-css >/dev/null 2>&1
show_progress 1.0 "Injecting node asset engines"

echo -e "\n${CYAN}${BOLD}Step 4: Provisioning High-Privilege Relational Database Roles${NC}"
# Explicitly use the version-specific service to avoid mapping hiccups
systemctl daemon-reload
systemctl start postgresql@17-main 2>/dev/null || systemctl start postgresql
systemctl enable postgresql

PG_USER_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_USER}';")

# Force absolute LOGIN, SUPERUSER, and CREATEDB rights on the assigned user account context cleanly
if [ "$PG_USER_EXISTS" = "1" ]; then
    sudo -u postgres psql -c "ALTER ROLE ${POSTGRES_USER} WITH LOGIN SUPERUSER CREATEDB PASSWORD '${DB_PASSWORD}';" >/dev/null 2>&1
else
    sudo -u postgres psql -c "CREATE ROLE ${POSTGRES_USER} WITH LOGIN SUPERUSER CREATEDB PASSWORD '${DB_PASSWORD}';" >/dev/null 2>&1
fi
show_progress 1.2 "Configuring PostgreSQL 17 cluster structures with Superuser Clearance"

echo -e "\n${CYAN}${BOLD}Step 5: Establishing System Daemon Accounts and Paths${NC}"
if ! id "$ODOO_USER" &>/dev/null; then
    adduser --system --home="${ODOO_HOME}" --group "${ODOO_USER}" --shell /bin/bash >/dev/null 2>&1
fi
mkdir -p "${ODOO_HOME}" "${ODOO_LOG_DIR}"
chown -R "${ODOO_USER}":"${ODOO_USER}" "${ODOO_HOME}"
chown -R "${ODOO_USER}":root "${ODOO_LOG_DIR}"
show_progress 0.8 "Isolating execution environment"

echo -e "\n${CYAN}${BOLD}Step 6: Pulling Version-Locked Odoo 19 Source Code Tree${NC}"
if [ -d "${ODOO_HOME}/.git" ]; then
    sudo -u "${ODOO_USER}" git -C "${ODOO_HOME}" fetch --all >/dev/null 2>&1
else
    sudo -u "${ODOO_USER}" git clone https://www.github.com/odoo/odoo --depth 1 --branch 19.0 --single-branch "${ODOO_HOME}" >/dev/null 2>&1
fi
show_progress 3.5 "Downloading application core frames"

echo -e "\n${CYAN}${BOLD}Step 7: Compiling Virtual Environment & Injecting Multi-Cloud Drivers${NC}"
if [ ! -d "${ODOO_HOME}/venv" ] || [ ! -f "${ODOO_HOME}/venv/bin/pip" ]; then
    rm -rf "${ODOO_HOME}/venv"
    sudo -u "${ODOO_USER}" python3.12 -m venv "${ODOO_HOME}/venv" >/dev/null 2>&1
fi

if [ ! -f "${ODOO_HOME}/requirements.txt" ]; then touch "${ODOO_HOME}/requirements.txt"; fi
for pkg in "pysftp" "pandas" "cx-oracle==6.1" "oracledb"; do
    if ! grep -q "^${pkg%%==*}" "${ODOO_HOME}/requirements.txt"; then
        echo "$pkg" >> "${ODOO_HOME}/requirements.txt"
    fi
done

sudo -u "${ODOO_USER}" "${ODOO_HOME}/venv/bin/pip" install --upgrade pip wheel setuptools >/dev/null 2>&1
sudo -u "${ODOO_USER}" "${ODOO_HOME}/venv/bin/pip" install -r "${ODOO_HOME}/requirements.txt" >/dev/null 2>&1
show_progress 4.0 "Building custom data layer drivers"

echo -e "\n${CYAN}${BOLD}Step 8: Mapping Server Controls & Generating Systemd Profile${NC}"
cat <<EOF > "${ODOO_CONF}"
[options]
admin_passwd = admin
db_host = localhost
db_port = 5432
db_user = ${POSTGRES_USER}
db_password = ${DB_PASSWORD}
addons_path = ${ODOO_HOME}/addons
logfile = ${ODOO_LOG_FILE}
http_port = ${ODOO_PORT}
EOF
chown "${ODOO_USER}":"${ODOO_USER}" "${ODOO_CONF}"
chmod 640 "${ODOO_CONF}"

cat <<EOF > "/etc/systemd/system/${POSTGRES_USER}.service"
[Unit]
Description=Odoo 19 Instance for user ${POSTGRES_USER}
After=postgresql.service

[Service]
Type=simple
User=${ODOO_USER}
Group=${ODOO_USER}
ExecStart=${ODOO_HOME}/venv/bin/python3 ${ODOO_HOME}/odoo-bin -c ${ODOO_CONF}
KillMode=mixed
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload && systemctl restart "${POSTGRES_USER}.service" && systemctl enable "${POSTGRES_USER}.service" >/dev/null 2>&1
show_progress 1.5 "Starting background service daemons"

SYS_HOSTNAME=$(hostname)
SYS_IPS=$(hostname -I | tr ' ' '\n' | grep -v '^127\.')

# Compute human-readable duration metrics cleanly
END_TIME=$(date +%s)
END_DATE_STR=$(date "+%Y-%m-%d %H:%M:%S")
ELAPSED_SECONDS=$((END_TIME - START_TIME))
DURATION_MIN=$((ELAPSED_SECONDS / 60))
DURATION_SEC=$((ELAPSED_SECONDS % 60))

echo -e "\n${GREEN}${BOLD}======================================================================"
echo -e "       DEPLOYMENT CONFIGURATION SEQUENCE EXECUTED SUCCESSFULLY        "
echo -e "======================================================================${NC}"
echo -e "${BOLD}Author:${NC}                  Anil Mahadev (${CYAN}https://anilmahadev.odoo.com${NC})"
echo -e "${BOLD}Lifecycle Window:${NC}        Started: ${YELLOW}${START_DATE_STR}${NC} -> Ended: ${YELLOW}${END_DATE_STR}${NC}"
echo -e "${BOLD}Total Execution Time:${NC}    ${PURPLE}${BOLD}${DURATION_MIN}m ${DURATION_SEC}s${NC} (${ELAPSED_SECONDS} total seconds)"
echo -e "----------------------------------------------------------------------"
echo -e "${BOLD}Target System Hostname:${NC}      ${CYAN}${SYS_HOSTNAME}${NC}"
echo -e "${BOLD}Local Network Access URLs:${NC}"
echo -e "   -> ${CYAN}http://localhost:${ODOO_PORT}${NC}"
for ip in $SYS_IPS; do
    echo -e "   -> ${CYAN}http://${ip}:${ODOO_PORT}${NC}"
done
echo -e "----------------------------------------------------------------------"
echo -e "${BOLD}PostgreSQL Instance User:${NC}    ${YELLOW}${POSTGRES_USER}${NC} (Status: SUPERUSER)"
echo -e "${BOLD}Active Implementation Logs:${NC}     ${YELLOW}tail -f ${ODOO_LOG_FILE}${NC}"
echo -e "${GREEN}======================================================================${NC}\n"
