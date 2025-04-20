#!/usr/bin/env bash
set -euo pipefail

# =================================================================
# Dynamic CodeQL Analyzer - Unified Installation, Setup, and Analysis
# =================================================================
# Version: 2.0
# Author: madedis 
# Description: Handles first-time users, existing setups, and CLI-style operations
# =================================================================

# ----------------------------------
# Configuration (Customizable)
# ----------------------------------
INSTALL_DIR="/opt/static_recon_codeql/workspace"  # Core installation directory
CLI_URL="https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip"
REPO_URL="https://github.com/github/codeql.git"
WORK_DIR="${WORK_DIR:-$(pwd)}"  # Default working directory

# ----------------------------------
# Color Codes & Logging
# ----------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${BLUE}[${timestamp}]${NC} $1" | tee -a "$WORK_DIR/codeql_auto.log"
}

show_help() {
  echo "Usage: $0 [--work-dir DIR] [--install-dir DIR] [--project-name NAME] COMMAND"
  echo "Commands: install, setup, create-db, analyze, full"
}

# ----------------------------------
# Core Functions
# ----------------------------------

install() {
  log "${GREEN}🚀 Initializing CodeQL Environment Setup...${NC}"
  
  if ! command -v unzip &>/dev/null || ! command -v git &>/dev/null; then
    log "${YELLOW}⚠ Installing System Dependencies...${NC}"
    sudo apt update && sudo apt install -y unzip git wget golang || { 
      log "${RED}⨯ Dependency Installation Failed"; exit 1 
    }
  fi

  CLI_DIR="$INSTALL_DIR/codeql-cli"
  if [[ ! -f "$CLI_DIR/codeql" ]]; then
    log "${YELLOW}⏳ Downloading CodeQL CLI...${NC}"
    wget -qO /tmp/codeql.zip "$CLI_URL" || { log "${RED}⨯ CLI Download Failed"; exit 1; }

    log "${YELLOW}⏳ Extracting CLI...${NC}"
    mkdir -p "$CLI_DIR"
    unzip -q /tmp/codeql.zip -d "$CLI_DIR" || { log "${RED}⨯ Extraction Failed"; exit 1; }
    rm -f /tmp/codeql.zip
  fi

  REPO_DIR="$INSTALL_DIR/codeql-repo"
  [[ ! -d "$REPO_DIR" ]] && {
    log "${YELLOW}⏳ Cloning Standard Packs...${NC}"
    git clone --depth 1 "$REPO_URL" "$REPO_DIR" || { log "${RED}⨯ Clone Failed"; exit 1; }
  }

  log "${GREEN}✅ Environment Setup Completed${NC}"
}

setup_project() {
  log "${GREEN}📂 Configuring Project Structure...${NC}"
  #
  PROJECT_PATH="$INSTALL_DIR/$PROJECT_NAME"
  declare -gA FOLDERS=(
    [artifacts]="$PROJECT_PATH/artifacts"
    [database]="$PROJECT_PATH/go-database"
    [results]="$PROJECT_PATH/go-database/results"
    [queries]="$INSTALL_DIR/${PROJECT_NAME}-queries"
  )

  for path in "${FOLDERS[@]}"; do
    if [[ ! -d "$path" ]]; then
      mkdir -p "$path" || { log "${RED}⨯ Failed creating $path"; continue; }
      log "${GREEN}✔ Created: ${path/$INSTALL_DIR\//}"
    else
      log "${YELLOW}✔ Exists: ${path/$INSTALL_DIR\//}"
    fi
  done
}

create_db() {
  local SRC_DIR="$1"
  log "${GREEN}📦 Building Database from: $SRC_DIR${NC}"
  
  DB_DIR="go-database"
  
  if [[ -d "$DB_DIR" && ! -f "$DB_DIR/qlpack.yml" ]]; then
    log "${YELLOW}⚠ Removing Corrupted Database...${NC}"
    rm -rf "$DB_DIR"
  fi

  CODEQL_BIN="$(find "$INSTALL_DIR/codeql-cli" -name codeql -type f | head -n1)"
  [[ -z "$CODEQL_BIN" ]] && { log "${RED}⨯ CodeQL CLI Missing"; exit 1; }

  log "${YELLOW}⏳ Creating Database...${NC}"
  "$CODEQL_BIN" database create "$DB_DIR" \
    --language=go \
    --source-root="$SRC_DIR"  || {
      log "${RED}⨯ Database Creation Failed"
      exit 1
    }

  log "${GREEN}✅ Database Created: ${DB_DIR/$INSTALL_DIR\//}${NC}"
}

analyze() {
  log "${GREEN}🔍 Starting Analysis Pipeline...${NC}"
  
  local QUERIES_DIR="" SRC_DIR="" FORMAT="sarifv2.1.0" AUTO_CREATE=true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --queries-dir) QUERIES_DIR="$2"; shift 2 ;;
      --src-dir) SRC_DIR="$2"; shift 2 ;;
      --format) FORMAT="$2"; shift 2 ;;
      --no-create) AUTO_CREATE=false; shift ;;
      *) log "${RED}⨯ Unknown Option: $1"; exit 1 ;;
    esac
  done

  [[ -z "$QUERIES_DIR" ]] && { log "${RED}⨯ --queries-dir Required"; exit 1; }
  [[ "$AUTO_CREATE" == true && -z "$SRC_DIR" ]] && { log "${RED}⨯ --src-dir Required"; exit 1; }

  if [[ "$AUTO_CREATE" == true ]]; then
    [[ ! -d "$SRC_DIR" ]] && { log "${RED}⨯ Source Directory Missing"; exit 1; }
    create_db "$SRC_DIR"
  fi

  CODEQL_BIN="$(find "$INSTALL_DIR/codeql-cli" -name codeql -type f | head -n1)"
  OUTPUT_FILE="$WORK_DIR/${PROJECT_NAME}.${FORMAT//[^a-zA-Z0-9]/_}"
  
  log "${YELLOW}⏳ Running $FORMAT Analysis...${NC}"
  "$CODEQL_BIN" database analyze \
    --additional-packs "$INSTALL_DIR/codeql-repo" \
    --format="$FORMAT" \
    --output="$OUTPUT_FILE" \
    "$PWD/go-database" \
    "$QUERIES_DIR" || {
      log "${RED}⨯ Analysis Failed"; exit 1
    }

  log "${GREEN}✅ Analysis Output: ${OUTPUT_FILE/$WORK_DIR\//}${NC}"

  BQRS_FILE="$(find "$PWD/go-database/results" -name '*.bqrs' -print -quit)"
  if [[ -f "$BQRS_FILE" ]]; then
    TXT_OUT="${BQRS_FILE%.bqrs}.txt"
    log "${YELLOW}⏳ Decoding BQRS Results...${NC}"
    "$CODEQL_BIN" bqrs decode \
      --format=text \
      --output="$TXT_OUT" \
      "$BQRS_FILE" || {
        log "${RED}⨯ Decoding Failed"; exit 1
      }
    log "${GREEN}✅ Decoded Results: ${TXT_OUT/$WORK_DIR\//}${NC}"
  else
    log "${YELLOW}⚠ No BQRS Files Found for Decoding${NC}"
  fi
}

# ----------------------------------
# Main Execution Flow
# ----------------------------------
PROJECT_NAME="$(basename "$PWD")"
COMMAND=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --work-dir) WORK_DIR="$2"; shift 2 ;;
    --install-dir) INSTALL_DIR="$2"; shift 2 ;;
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    install|setup|create-db|analyze|full) COMMAND="$1"; shift; break ;;
    -h|--help) show_help; exit 0 ;;
    *) log "${RED}⨯ Invalid Option: $1"; show_help; exit 1 ;;
  esac
done

[[ -z "${COMMAND:-}" ]] && { log "${RED}⨯ No Command Specified"; show_help; exit 1; }

case "$COMMAND" in
  install)
    install "$@"
    ;;
  setup)
    setup_project "$@"
    ;;
  create-db)
    [[ -z "${1:-}" ]] && { log "${RED}⨯ Missing --src-dir"; exit 1; }
    create_db "$1"
    ;;
  analyze)
    analyze "$@"
    ;;
  full)
    install
    setup_project
    [[ -z "${1:-}" || -z "${2:-}" ]] && { log "${RED}⨯ Missing --src-dir or --queries-dir"; exit 1; }
    create_db "$1"
    analyze --queries-dir "$2"
    ;;
  *)
    log "${RED}⨯ Invalid Command"; show_help; exit 1
    ;;
esac

log "${GREEN}✅ Successfully Completed: $COMMAND${NC}"
