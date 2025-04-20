# CodeQL Go Automation Suite : install setup and start analyzing golang source code

A Bash tool to install the CodeQL CLI, pull in the official packs, scaffold your Go project workspace, build a CodeQL database, run custom queries, and decode results. No bs—just repeatable steps and clear outputs.

---

## Why Use This Script?

Maintaining a secure Go codebase means running CodeQL scans regularly. This single script gives you:

- **One-command install** of CodeQL CLI and official packs  
- **Dynamic workspace setup** for any project name  
- **Automated database creation** from your Go code  
- **Query execution** with SARIF output  
- **BQRS decoding** into human‑readable text  
- **Modular commands** so you can pick and choose  

---

## Prerequisites

- **Linux** (Debian‑family, Ubuntu, Parrot, etc.)  
- **Bash** (version 4+)  
- **sudo** privileges  
- **Internet** access for downloads  
- **Go toolchain** installed (required for database build)  

---

## Installation

1. Clone this repo (or copy `main.sh`) into your workspace:
   ```bash
   git clone https://github.com/madedis/CodeQL-Automation-Tool.git
   cd CodeQL-Automation-Tool
   ```
2. Make the script executable:
   ```bash
   chmod +x main.sh
   ```

---

## Usage

```bash
./main.sh [GLOBAL OPTIONS] <command> [COMMAND OPTIONS]
```

### Global Options

- `--work-dir DIR`       	# Directory for logs and outputs (default: current directory)
- `--install-dir DIR`    	# Where to install CodeQL CLI and packs (default: `/opt/static_recon_codeql/workspace`)
- `--cli-url URL`        	# URL to download CodeQL CLI zip
- `--repo-url URL`       	# Git URL for CodeQL packs (default: GitHub official repo)
- `--project-name NAME`  	# Identifier for your project (default: name of CWD)

### Commands

| Command   | Description                                                                                                  |
|-----------|--------------------------------------------------------------------------------------------------------------|
| `install` | Install CodeQL CLI and clone the official packs repository.                                                  |
| `setup`   | Create project folder structure under the install directory.                                                  |
| `create-db` | Build and create a Go CodeQL database from source.                                                          |
| `analyze` | Run CodeQL queries against the database and decode results to text/SARIF.                                     |
| `full`    | Execute `install`, `setup`, `create-db`, and `analyze` in one go (requires `--src-dir` and `--queries-dir`). |

Run `./main.sh <command> --help` for command-specific options.

---

## Examples

1. **Install CodeQL CLI & packs**
   ```bash
   ./main.sh --install-dir ~/codeql_workspace install
   ```

2. **Setup a project**
   ```bash
   ./main.sh setup --project-name my-go-app
   ```

3. **Create a database from source**
   ```bash
   ./main.sh create-db --src-dir /path/to/my-go-app
   ```

4. **Analyze with custom queries**
   ```bash
   ./main.sh analyze --queries-dir ~/custom-ql-packs --format sarifv2.1.0
   ```

5. **Full run**
   ```bash
   ./main.sh full --src-dir ./ --queries-dir ./queries
   ```

---

## Logging

All script actions are logged to `<WORK_DIR>/codeql_auto.log` with timestamps. Inspect this file if something goes sideways.




