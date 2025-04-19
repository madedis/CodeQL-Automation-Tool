#!/usr/bin/env bash

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# sriptfor Dealing with the CodeQl setup will be created later .
############################################################################################################################################################
#
# First thing :
#    
#  arti_d_c  var directory where stored : artifact database creation,
#   
#  base_dir  var directory where stored : the created query, qlpack.yml, result-of-the-query-executed.sarif
#  
#  N.B : make sure the pack.yml is and object containing "name":"value" , value here is the the directorty name where the mentionned files are stored.
#  
#  state_res var directory where stored : the results folder mentionned in the database analyze :  of the query in the databases directory.
# 
# saving all commands cli : codeql database creation and database analyze . 
# parsinng all args supplied : the directory where the first arg and second arg are containing all necessary ressources, to run codeql cli  command cases.  
# 
# Here we gonna automate the process of : 
# Creating a go databases using codeql database create  and  a cloned git repo and CodeQl cli Command codeql data for the codebase we need to analyze.
# Analysis off a go dabatase using codeql database analyze cli command and using the database created and a stored in an directory.
# 
# Processing the artifact of the database analyze : we choose to use CodeQl and Vim instead of Vscode which needs some automation for smothly using Codeql.
#
# ─────────────────────────────────────────────────────────────────────────────
#
# 1 locate the bqrs file. 
# 2 prepare for decoding file.
# 3 decode the bqrs file.    
# 
# ─────────────────────────────────────────────────────────────────────────────
# CodeQL Automation Tool (Structured & Secure)
#   - Uses associative arrays for configuration
#   - Enhanced command-line interface
#   - Improved validation and error handling
# ─────────────────────────────────────────────────────────────────────────────

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize configuration associative array
declare -A CONFIG

# Default configuration file path
CONFIG_FILE="./qlconf.cfg"

# ────────────── Function Definitions ──────────────
show_help() {
  echo -e "${YELLOW}Usage:${NC}"
  echo "  $0 [OPTIONS]"
  echo
  echo -e "${YELLOW}Options:${NC}"
  echo "  -c, --config FILE    Specify configuration file (default: ./qlconf.cfg)"
  echo "  -h, --help           Show this help message"
  echo
  echo -e "${YELLOW}Description:${NC}"
  echo "  Automated CodeQL analysis workflow with SARIF output and BQRS decoding"
}

load_config() {
  local config_file="$1"
  if [[ ! -f "$config_file" ]]; then
    echo -e "${RED} Config file not found: $config_file${NC}"
    exit 1
  fi
  
  # Source configuration file
  source "$config_file"
  
  # Populate associative array from sourced variables
  CONFIG=(
    [arti_d_c]="$arti_d_c"
    [base_dir]="$base_dir"
    [state_res]="$state_res"
    [filesarif]="$filesarif"
    [query_file_name]="$query_file_name"
    [codeql_cli]="$codeql_cli"
    [database_dir]="$database_dir"
    [additional_packs]="$additional_packs"
    [query_pack]="$query_pack"
  )
}

validate_config() {
  declare -A REQUIRED_KEYS=(
    [arti_d_c]="Artifact directory configuration"
    [base_dir]="Base working directory"
    [state_res]="State/results directory"
    [filesarif]="SARIF output filename base"
    [query_file_name]="Query file name base"
    [codeql_cli]="CodeQL CLI executable path"
    [database_dir]="CodeQL database directory"
    [additional_packs]="Additional CodeQL packs"
    [query_pack]="Query pack specification"
  )

  local missing=0
  for key in "${!REQUIRED_KEYS[@]}"; do
    if [[ -z "${CONFIG[$key]:-}" ]]; then
      echo -e "${RED} Missing required configuration: ${REQUIRED_KEYS[$key]} ($key)${NC}"
      missing=1
    fi
  done

  if [[ $missing -ne 0 ]]; then
    exit 1
  fi
}

# ────────────── Main Execution ──────────────

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED} Unknown option: $1${NC}"
      show_help
      exit 1
      ;;
  esac
done

# Load and validate configuration
load_config "$CONFIG_FILE"
validate_config

# ────────────── Path Calculations ──────────────
bqrs_file="${CONFIG[query_file_name]}.bqrs"
text_report="${CONFIG[query_file_name]}.txt"
bqrs_path="${CONFIG[state_res]}/$bqrs_file"
txt_output_path="${CONFIG[state_res]}/$text_report"
sarif_output="${CONFIG[base_dir]}/${CONFIG[filesarif]}.sarif"

# Create output directory if needed
mkdir -p "${CONFIG[state_res]}"

# ────────────── Analysis Stage ──────────────
echo -e "${GREEN}🔍 Starting CodeQL analysis...${NC}"
"${CONFIG[codeql_cli]}" database analyze \
  --additional-packs "${CONFIG[additional_packs]}" \
  "${CONFIG[database_dir]}" \
  "${CONFIG[query_pack]}" \
  --format=sarifv2.1.0 \
  --output="$sarif_output"

# ────────────── Results Processing ──────────────
if [[ ! -f "$bqrs_path" ]]; then
  echo -e "${RED} BQRS file not found at: $bqrs_path${NC}"
  exit 1
fi

echo -e "${GREEN} Converting BQRS results to readable format...${NC}"
"${CONFIG[codeql_cli]}" bqrs decode \
  --format=text \
  --output="$txt_output_path" \
  -- "$bqrs_path"

# ────────────── Final Output ──────────────
echo -e "\n${GREEN} Analysis complete!${NC}"
echo -e "${YELLOW}► SARIF Report:${NC} $sarif_output"
echo -e "${YELLOW}► Text Report: ${NC} $txt_output_path"
