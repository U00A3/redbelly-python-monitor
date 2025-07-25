# 🔴 Redbelly Node Status Monitor

<div align="center">

![Redbelly Logo](https://img.shields.io/badge/Redbelly-Network-red?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMTIiIGN5PSIxMiIgcj0iMTAiIGZpbGw9IiNGRjAwMDAiLz4KPHN2Zz4K)
![Python](https://img.shields.io/badge/Python-3.7+-blue?style=for-the-badge&logo=python)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)

**🚀 Simple Command-line Tool for Live Monitoring of Redbelly Blockchain Nodes**

*Get comprehensive insights into your node's performance, network status, and blockchain metrics*

</div>

---

## 🔧 Prerequisites

### 🐍 **Python Requirements**
- **Python 3.7+** (Recommended: Python 3.9+)
- **pip** package manager

### 📦 **Required Packages**
```bash
requests>=2.25.0
python-dateutil>=2.8.0
```

### 🔴 **Redbelly Node Requirements**
Your Redbelly node must be configured with:
- ✅ Status server enabled
- ✅ Prometheus metrics enabled
- ✅ Proper network access

---

## 📦 Installation

### 🚀 **Quick Install**

```bash
# 1️⃣ Clone the repository
git clone https://github.com/U00A3/redbelly-python-monitor.git
cd redbelly-python-monitor

# 2️⃣ Install dependencies
pip3 install -r requirements.txt

# 3️⃣ Make executable (optional)
chmod +x status.py

# 4️⃣ Test connection
python3 status.py --help
```

## ⚙️ Configuration

### 🔴 **Redbelly Node Setup**

Ensure your Redbelly node is running with these flags:

```bash
# Required flags for monitoring
--statusserver.addr=127.0.0.1
--statusserver.port=6539
--prometheus.addr=127.0.0.1
--prometheus.port=6539
```

### 🌐 **Network Configuration**

For remote monitoring, ensure firewall allows access to:
- **Port 6539** - Status server and Prometheus metrics
- **Proper networking** - Node accessible from monitoring location

---

## 🚀 Quick Start

### 🏃‍♂️ **Basic Usage**
```bash
# Monitor local node (default settings)
python3 status.py

# Monitor remote node
python3 status.py -a http://your-node-ip:6539

# Custom refresh rate and balance threshold
python3 status.py -a http://xxx.xxx.xx.xx:6539 -mb 50 -r 15
```

### 🎯 **One-liner Examples**
```bash
# Production monitoring with alerts
python3 status.py -a http://mainnet-node:6539 -mb 100 -r 30

# Development monitoring (fast refresh)
python3 status.py -a http://localhost:6539 -r 2

# Conservative monitoring (slow refresh, high threshold)
python3 status.py -mb 500 -r 60
```

---

## 🛠️ Included Utility Scripts

This repository contains several helpful scripts in the `scripts/` folder to make node monitoring and troubleshooting easier, even for non-technical users:

### 1. `setup-monitoring.sh`
**Purpose:**  
Automatically configures your Redbelly node for monitoring.  
**How to use:**  
1. Open a terminal.
2. Go to the project folder:  
   ```bash
   cd redbelly-python-monitor/scripts
   ```
3. Run the script with administrator rights:  
   ```bash
   sudo ./setup-monitoring.sh
   ```
4. Follow the on-screen instructions.  
*This script will safely update your node configuration and open the necessary ports for monitoring.*

---

### 2. `check-node-health.sh`
**Purpose:**  
Quickly checks if your node is running correctly and shows a simple health summary.  
**How to use:**  
1. Open a terminal.
2. Go to the scripts folder:  
   ```bash
   cd redbelly-python-monitor/scripts
   ```
3. Run the script:  
   ```bash
   ./check-node-health.sh
   ```
4. Read the results.  
*You will see information about node status, balance, synchronization, and possible issues.*

---

### 3. `diagnose.sh`
**Purpose:**  
Performs a full diagnostic of your node and system, checking services, configuration, network, and more.  
**How to use:**  
1. Open a terminal.
2. Go to the scripts folder:  
   ```bash
   cd redbelly-python-monitor/scripts
   ```
3. Run the script:  
   ```bash
   ./diagnose.sh
   ```
4. Review the detailed report.  
*This script is helpful if you need to troubleshoot problems or share diagnostics with support.*

---

**Tip:**  
If you see a "Permission denied" error, make the script executable:  
```bash
chmod +x scriptname.sh
```
Replace `scriptname.sh` with the name of the script you want to run.

---

---

## 📊 Monitoring Dashboard

### 🎨 **Live Dashboard Example**

```
🔴 Monitoring url http://xxx.xxx.xx.xx:6539/status

📊 Sync Status:
✅ Node has completed initial sync

🧱 Block Information:
Current block: 2,421,719
Last block from governors: 2,421,719
Last sync with governors: Sunday, 08-Jun-25 19:43:03 BST
Blocks downloaded: 6,559
Pending blocks: 0

🏛️ Superblock Information:
Current superblock: 1,709,275
Last superblock from bootnodes: 1,709,275
Last sync with bootnodes: Sunday, 08-Jun-25 19:42:45 BST

🌐 Network Information:
Governor count: 33
Is governor: ❌ NO
Permission extenders: 1

💰 Transaction Information:
Successful transactions: 6,562
Failed transactions: 0
Total gas used: 842,161,236
Pending gas: 0

⚡ Performance Metrics:
Total CPU time: 3.48h
Memory usage: 671.02 MB
Active goroutines: 366
File descriptors: 10,771/524,288 (2.1%)
Avg block process time: 1.77ms

💎 Price Information:
RBNT/USD price: $0.024236
Gas fees (USD per 21k units): $0.0100

🔐 Certificate Information:
DNS names: redbelly-node.bloodmoon.ltd
Valid until: 08/24 05:45:21PM '25 +0000

🔑 Signing Address Information:
Address: 0xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Balance: 999.999971428571532974 RBNT

🔒 Permission Cache:
Cache hits: 5,942
Cache misses: 620
Cache hit rate: 90.6%

🏷️ Version: 1.2.0 970d4cf184711e3e538b7e861d0e97da5bf793d1
```

---

## 🎛️ Command Line Options

| Parameter | Short | Long | Default | Description |
|-----------|-------|------|---------|-------------|
| **Address** | `-a` | `--address` | `http://localhost:6539` | 🌐 Redbelly node status server URL |
| **Min Balance** | `-mb` | `--minBalance` | `10` | 💰 Minimum RBNT balance before warning |
| **Refresh Rate** | `-r` | `--refreshSeconds` | `5` | ⏱️ Update frequency in seconds |
| **Help** | `-h` | `--help` | - | 📖 Show help message |

### 💡 **Usage Examples**

```bash
# 🏠 Local node monitoring
python3 status.py

# 🌍 Remote node with custom settings
python3 status.py -a http://remote-node:6539 -mb 100 -r 10

# 🚨 High-frequency monitoring for debugging
python3 status.py -r 1 -mb 5

# 🐌 Low-frequency monitoring for production
python3 status.py -r 300 -mb 1000
```

---

## 📈 Metrics Overview

<details>
<summary><b>🧱 Block & Superblock Metrics</b></summary>

- **Block Index** - Current blockchain height
- **Block Processing Time** - Average time to process blocks
- **Blocks Downloaded** - Total blocks synchronized
- **Pending Blocks** - Blocks waiting for processing
- **Superblock Status** - Superblock synchronization state
- **Governor Sync** - Last synchronization with governors

</details>

<details>
<summary><b>🌐 Network & Governance</b></summary>

- **Governor Count** - Number of active governors
- **Node Role** - Whether this node is a governor
- **Permission Extenders** - Network permission managers
- **Network Health** - Overall network status

</details>

<details>
<summary><b>💰 Transaction & Economic</b></summary>

- **Transaction Success Rate** - Ratio of successful transactions
- **Gas Usage** - Total gas consumed by transactions
- **Pending Gas** - Gas waiting for distribution
- **RBNT Price** - Live market price
- **Gas Fees** - Current network fees

</details>

<details>
<summary><b>⚡ Performance & System</b></summary>

- **CPU Usage** - Total CPU time consumed
- **Memory Usage** - RAM consumption
- **Goroutines** - Active Go routines
- **File Descriptors** - Open file handles
- **Cache Performance** - Permission cache efficiency

</details>

---

## ⚠️ Warning System

### 🚨 **Critical Alerts**

| Warning Type | Trigger | Display |
|--------------|---------|---------|
| **Low Balance** | Balance < minimum threshold | 🔴 `⚠️ WARNING: balance is below minimum` |
| **Sync Issues** | Node out of sync | 🟡 `⏳ Node is still running initial sync` |
| **High Resource Usage** | Memory/CPU limits | 🔴 Resource usage warnings |
| **Certificate Expiry** | Cert expires soon | 🟠 Certificate expiration alert |

### 🎨 **Color Coding**
- 🟢 **Green** - Normal operation
- 🟡 **Yellow** - Attention needed
- 🔴 **Red** - Critical issues
- 🔵 **Blue** - Informational

---

## 🛠️ Troubleshooting

<details>
<summary><b>🔌 Connection Issues</b></summary>

**Problem**: `Connection refused` or timeout errors

**Solutions**:
1. ✅ Verify node is running
2. ✅ Check status server flags: `--statusserver.addr=127.0.0.1 --statusserver.port=6539`
3. ✅ Test connectivity: `curl http://your-node:6539/status`
4. ✅ Check firewall settings

</details>

<details>
<summary><b>📊 Missing Metrics</b></summary>

**Problem**: Some metrics show as unavailable

**Solutions**:
1. ✅ Ensure Prometheus is enabled on the node
2. ✅ Verify `/metrics` endpoint: `curl http://your-node:6539/metrics`
3. ✅ Check node version compatibility
4. ✅ Review node configuration flags

</details>

<details>
<summary><b>🐍 Python Issues</b></summary>

**Problem**: Import errors or compatibility issues

**Solutions**:
1. ✅ Use Python 3.7+: `python3 --version`
2. ✅ Install dependencies: `pip3 install -r requirements.txt`
3. ✅ Check module availability: `python3 -c "import requests, dateutil"`

</details>

<details>
<summary><b>🔑 Permission Errors</b></summary>

**Problem**: Access denied or permission issues

**Solutions**:
1. ✅ Run with appropriate permissions
2. ✅ Check node access controls
3. ✅ Verify network connectivity
4. ✅ Review firewall rules

</details>

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### 🎯 **Ways to Contribute**
- 🐛 **Bug Reports** - Found an issue? Let us know!
- 💡 **Feature Requests** - Have ideas? Share them!
- 🔧 **Code Contributions** - Submit pull requests
- 📖 **Documentation** - Help improve docs
- 🧪 **Testing** - Test on different configurations

```
### 📋 **Contribution Guidelines**
- ✅ Follow PEP 8 style guidelines
- ✅ Add tests for new features
- ✅ Update documentation
- ✅ Test with multiple node configurations

---
### 🌟 **Show Your Support**
If this tool helps you, please:
- ⭐ **Star the repository**
- 🍴 **Fork and contribute**
- 📢 **Share with others**
- 💝 **Sponsor development**

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License - Feel free to use, modify, and distribute
Copyright (c) 2024 Redbelly Node Monitor Contributors
```

---

<div align="center">

**🔴 Made with ❤️ for the Redbelly Community**

*🚀 Happy Monitoring! 🚀*

</div> 