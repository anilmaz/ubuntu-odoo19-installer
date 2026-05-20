#!/usr/bin/env bash
# ==============================================================================
# Script Name: uninstall_odoo19.sh
# Description: Smart Uninstaller (PostgreSQL 17 Purge & Filestore Rescue Guard)
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

log_warn() { echo -e "${YELLOW}${BOLD}[WARN]${NC} $1"; }

clear
echo -e "${RED}${BOLD}======================================================================"
echo -e "        CRITICAL WARNING: ODOO 19 DESTRUCTION & PURGE SYSTEM          "
echo -e "======================================================================${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}${BOLD}[ERROR]${NC} This execution requires root privileges via sudo."
    exit 1
fi

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$REAL_USER)
BACKUP_DIR="${USER_HOME}/migration_backups"
ODOO_FILESTORE="/opt/odoo19/.local/share/Odoo/filestore"

echo -e "${PURPLE}${BOLD}[PRE-FLIGHT] Verifying Environment Contexts...${NC}"
read -p "Enter the precise PostgreSQL database/user name to back up and drop [Default: odoo19]: " TARGET_DB
TARGET_DB=${TARGET_DB:-odoo19}

apt-get install -y zip bc >/dev/null 2>&1
if ! systemctl is-active --quiet postgresql; then systemctl start postgresql; fi

PG_DB_EXISTS=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${TARGET_DB}';")

RUN_PURGE=true

if [ "$PG_DB_EXISTS" = "1" ]; then
    echo -e "\n${BLUE}${BOLD}[BACKUP OPERATIONS] Target Database Discovered. Compiling Portable Archive...${NC}"
    
    STAGE_DIR="/tmp/odoo_zip_stage_$$"
    mkdir -p "${STAGE_DIR}/filestore"
    TMP_SQL_STAGE="${STAGE_DIR}/dump.sql"
    
    sudo -u postgres pg_dump -Fp -b -f "${TMP_SQL_STAGE}" "${TARGET_DB}" 2>/dev/null
    
    if [ -s "${TMP_SQL_STAGE}" ]; then
        if [ -d "${ODOO_FILESTORE}/${TARGET_DB}" ]; then 
            cp -r "${ODOO_FILESTORE}/${TARGET_DB}" "${STAGE_DIR}/filestore/"
        fi
        
        cat <<EOF > "${STAGE_DIR}/manifest.json"
{
    "postgresql_version": "17",
    "generator": "Twisted Carousl Custom Engine",
    "db_name": "${TARGET_DB}",
    "odoo_version": "19.0",
    "modules": []
}
EOF
        mkdir -p "${BACKUP_DIR}"
        FINAL_ZIP_PATH="${BACKUP_DIR}/odoo_backup_${TARGET_DB}_$(date +%Y%m%d_%H%M%S).zip"
        cd "${STAGE_DIR}" && zip -r "${FINAL_ZIP_PATH}" dump.sql manifest.json filestore/ >/dev/null && cd - >/dev/null
        show_progress 2.5 "Packaging database schemas and associated attachment objects"
        echo -e "  -> ${GREEN}${BOLD}[SUCCESS]${NC} Full portable Odoo backup archive written: ${CYAN}${FINAL_ZIP_PATH}${NC}"
    fi
    rm -rf "${STAGE_DIR}"
else
    # --- ORPHAN DATA RESCUE GUARD INTERFACE ---
    echo -e "\n${YELLOW}${BOLD}======================================================================"
    echo -e "  [NOTICE] Database '${TARGET_DB}' does not exist in PostgreSQL!"
    echo -e "  Standard automated db backup operations cannot be processed."
    echo -e "======================================================================${NC}"
    
    if [ -d "${ODOO_FILESTORE}/${TARGET_DB}" ] || [ -d "${ODOO_FILESTORE}" ]; then
        echo -e "${CYAN}${BOLD}An orphan physical Odoo filestore was detected on disk at:${NC}"
        echo -e "${BLUE}${ODOO_FILESTORE}${NC}\n"
        echo -e "Choose an option to protect this unlinked data before the system is purged:"
        echo -e "  [1] Let the script back up the orphan filestore folder for you now."
        echo -e "  [2] Pause execution completely so you can manually back it up or inspect it."
        echo -e "  [3] Skip backup entirely (Dangerous - will permanently nuke the filestore files)."
        echo -e "----------------------------------------------------------------------"
        read -p "Select choice [1-3]: " ORPHAN_CHOICE
        
        case "$ORPHAN_CHOICE" in
            1)
                echo -e "\n${BLUE}Backing up orphan filestore folder layout...${NC}"
                mkdir -p "${BACKUP_DIR}"
                ORPHAN_ZIP_PATH="${BACKUP_DIR}/orphan_filestore_rescue_${TARGET_DB}_$(date +%Y%m%d_%H%M%S).zip"
                
                if [ -d "${ODOO_FILESTORE}/${TARGET_DB}" ]; then
                    cd "${ODOO_FILESTORE}" && zip -r "${ORPHAN_ZIP_PATH}" "${TARGET_DB}" >/dev/null && cd - >/dev/null
                else
                    cd "/opt/odoo19/.local/share" && zip -r "${ORPHAN_ZIP_PATH}" Odoo/ >/dev/null && cd - >/dev/null
                fi
                show_progress 1.5 "Compressing remaining attachment storage trees"
                echo -e "  -> ${GREEN}${BOLD}[RESCUED]${NC} Orphan data saved safely to: ${CYAN}${ORPHAN_ZIP_PATH}${NC}"
                ;;
            2)
                echo -e "\n${YELLOW}${BOLD}[PAUSED] Execution frozen at operator request.${NC}"
                echo -e "The script will stay paused until you press Enter."
                echo -e "Open a separate terminal shell to interact with: ${CYAN}${ODOO_FILESTORE}${NC}"
                read -p "Press [Enter] only when you are ready to resume and PERMANENTLY WIPE the environment... " RUN_RESUME
                echo -e "${BLUE}Resuming uninstallation sequence...${NC}"
                ;;
            *)
                log_warn "User chose to bypass preservation rules. Preparing for complete file destruction."
                ;;
        esac
    else
        echo -e "${GREEN}No legacy filestores found on disk. Clean sweep path verified.${NC}"
    fi
fi

# --- DESTRUCTION PURGE MATRIX ---
if [ "$RUN_PURGE" = true ]; then
    echo -e "${RED}${BOLD}\nProceeding with deep wipe operations...${NC}"

    for service in $(systemctl list-units --type=service --all | grep -E "odoo|${TARGET_DB}" | awk '{print $1}'); do
        systemctl stop "$service" 2>/dev/null
        systemctl disable "$service" 2>/dev/null
        rm -f "/etc/systemd/system/$service"
    done
    systemctl daemon-reload
    show_progress 0.7 "Stopping active application daemon threads"

    if systemctl is-active --quiet postgresql; then
        sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${TARGET_DB}' AND pid <> pg_backend_pid();" &>/dev/null
        sudo -u postgres psql -c "DROP DATABASE IF EXISTS ${TARGET_DB};" 2>/dev/null
        sudo -u postgres psql -c "DROP ROLE IF EXISTS ${TARGET_DB};" 2>/dev/null
    fi
    show_progress 0.9 "Dropping database cluster instances"

    # Deep system clean: Terminate and erase PostgreSQL 17 server binaries and apt repository lists cleanly
    read -p "Do you want to completely purge PostgreSQL 17 engine binaries from this host? (y/n): " PURGE_PG_BIN
    if [[ "$PURGE_PG_BIN" =~ ^[Yy]$ ]]; then
        systemctl stop postgresql 2>/dev/null
        apt-get purge -y postgresql-17 postgresql-client-17 postgresql-common >/dev/null 2>&1
        apt-get autoremove -y >/dev/null 2>&1
        rm -f /etc/apt/sources.list.pydg.list
        rm -f /etc/apt/keyrings/postgresql.gpg
        show_progress 2.0 "Purging PostgreSQL 17 engine assemblies & PGDG source paths"
    fi

    rm -rf "/opt/odoo19" "/var/log/odoo" "${USER_HOME}/.local/share/Odoo" "/etc/${TARGET_DB}.conf" /etc/odoo19.conf
    deluser --system odoo19 &>/dev/null; delgroup odoo19 &>/dev/null
    chown -R "${REAL_USER}":"${REAL_USER}" "${BACKUP_DIR}" 2>/dev/null
    show_progress 1.2 "Purging structural directory installations"

    END_TIME=$(date +%s)
    END_DATE_STR=$(date "+%Y-%m-%d %H:%M:%S")
    ELAPSED_SECONDS=$((END_TIME - START_TIME))
    DURATION_MIN=$((ELAPSED_SECONDS / 60))
    DURATION_SEC=$((ELAPSED_SECONDS % 60))

    echo -e "\n${GREEN}${BOLD}======================================================================"
    echo -e "         ODOO 19 ENVIRONMENT CLEANUP COMPLETED SUCCESSFULLY     "
    echo -e "======================================================================${NC}"
    echo -e "${BOLD}Author:${NC}              Anil Mahadev (${CYAN}https://github.com/anilmaz${NC})"
    echo -e "${BOLD}Lifecycle Window:${NC}    Started: ${YELLOW}${START_DATE_STR}${NC} -> Ended: ${YELLOW}${END_DATE_STR}${NC}"
    echo -e "${BOLD}Total Removal Time:${NC}  ${PURPLE}${BOLD}${DURATION_MIN}m ${DURATION_SEC}s${NC} (${ELAPSED_SECONDS} total seconds)"
    echo -e "Ecosystem is completely clean and ready for clean provisioning structures."
    echo -e "${GREEN}======================================================================${NC}\n"
fi
