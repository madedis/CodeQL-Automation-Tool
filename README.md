# CodeQL Go Automation Suite : install setup and start analyzing golang source code

A Bash tool to install the CodeQL CLI, pull in the official packs, build your Go project workspace, build a CodeQL database, run custom queries, and decode results. No bs—just repeatable steps and clear outputs.

---

# What It Does
- Automated CodeQL CLI and pack installation
- Project structure scaffolding
- Go code database creation
- Static analysis with SARIF/BQRS outputs
- Automatic result decoding to text
- Unified commands for different workflows

## Requirements
- **Bash** (Linux environment)
- **CodeQL CLI** (auto-installed)
- **CodeQL Queries** (auto-installed)
- `unzip`, `git`, `wget`, `golang` (auto-installed if missing)
- Tested on Debian/Ubuntu systems

# Installation
```bash
git clone https://github.com/madedis/CodeQL-Automation-Tool.git
cd codeql-analyzer
chmod +x main.sh
```

## Usage
```bash
sudo ./main.sh [OPTIONS] COMMAND [PARAMETERS]
```

### Options
- `--work-dir DIR`: Set working directory (default: current)
- `--install-dir DIR`: Set installation root (default: /opt/static_recon_codeql/workspace)
- `--project-name NAME`: Set project name (default: current directory name)

### Commands
1. **Install Dependencies**
   ```bash
   sudo ./main.sh install
   ```

2. **Create Project Structure**
   ```bash
   sudo ./main.sh setup
   ```

3. **Create Code Database**
   ```bash
   sudo ./main.sh create-db /path/to/source-code
   ```

4. **Run Analysis**
   ```bash
   sudo ./main.sh analyze --queries-dir /path/to/queries --src-dir /path/to/source
   ```

5. **Full Pipeline**
   ```bash
   sudo ./main.sh full /path/to/source /path/to/queries
   ```

## Analysis Workflow
1. **Install Core Components**
   ```bash
   sudo ./main.sh install
   ```

2. **Initialize Project**
   ```bash
   sudo ./main.sh setup --project-name myapp
   ```

3. **Build & Analyze**
   ```bash
   sudo ./main.sh full ./src ./security-queries
   ```

## Output Structure
```
📂 install-dir/
├── codeql-cli/          # CLI binaries
├── codeql-repo/         # Standard queries
└── [project-name]/
    ├── artifacts/       # Analysis artifacts(optional)
    ├── go-database/     # CodeQL database
    └── results/         # Analysis results (SARIF/TXT)
```

## Notes
1. First run requires `sudo` for package installations
2. Default analysis format is SARIF v2.1.0
3. Logs stored in `codeql_auto.log`
4. Customize `INSTALL_DIR` in script for different locations

## Troubleshooting
- **Missing Dependencies**: Ensure `apt` access and internet connection
- **Database Errors**: Delete corrupted `go-database` folder and retry
- **Permission Issues**: Run with `sudo` for system-wide installation
