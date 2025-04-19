

#  CodeQL Automation Tool for Golang (Secure & Structured) / Combining Vim + CodeQL

> Automate your CodeQL queries with confidence. This tool provides a **secure**, **flexible**, and **production-ready** way to run CodeQL queries, output SARIF reports, and decode BQRS results with minimal setup.

---

###  Features

-  Supports `.bqrs` decoding and `.sarif` generation
-  Fully configurable with an external `.cfg` file
-  Validates inputs and paths before execution
-  Uses associative arrays for clean logic
-  Color-coded output for clarity
-  Easily extensible for additional formats or stages

---

### 🛠️ Setup

#### 1. Clone this repo

```bash
git clone https://github.com/yourusername/codeql-secure-automation.git
cd codeql-secure-automation
```

#### 2. Create and configure your `.cfg` file

Example `qlconf.cfg`:

```bash
arti_d_c="/opt/static_recon_codeql/workspace/nebula/artifacts"
base_dir="/opt/static_recon_codeql/workspace/nebula/my-query-go"
state_res="/opt/static_recon_codeql/workspace/nebula/go-database/results/my-go-query"
filesarif="nebula_res"
query_file_name="firstquery"

codeql_cli="/opt/static_recon_codeql/workspace/codeql-cli/codeql"
database_dir="/opt/static_recon_codeql/workspace/nebula/go-database"
additional_packs="/root/.codeql/packages"
query_pack="my-query-go"
```

---

###  Usage

```bash
chmod +x run-codeql.sh
./run-codeql.sh -c qlconf.cfg
```

Or use the default config (`./qlconf.cfg`):

```bash
./run-codeql.sh
```

####  Help menu

```bash
./run-codeql.sh -h
```

---

### 📂 Output Files

- ✅ SARIF Report: `${base_dir}/${filesarif}.sarif`
- ✅ Text Report: `${state_res}/${query_file_name}.txt`

These outputs can be used in CI pipelines, GitHub Advanced Security (GHAS), or for local inspection.

---

### 🔒 Security Notes

- All configuration values are **strictly validated**.
- No unescaped shell execution is used.
- Ideal for multi-user environments and CI/CD pipelines.
- No risk of privilege escalation or arbitrary code execution via `eval`.

---

### 🧪 Testing Configurations

Want to run multiple configurations? Just pass different `.cfg` files:

```bash
./run-codeql.sh -c test1.cfg
./run-codeql.sh -c test2.cfg
```

### 🤝 Contributions

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

