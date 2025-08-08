# Internet Connection Monitor 🌐

![Docker Pulls](https://img.shields.io/docker/pulls/syntaxsorcerer7/internet-monitor)
![Docker Image Size](https://img.shields.io/docker/image-size/syntaxsorcerer7/internet-monitor)
![Docker Stars](https://img.shields.io/docker/stars/syntaxsorcerer7/internet-monitor)

A containerized internet monitoring tool that continuously tracks your internet connection availability and visualizes it in a clear web interface with professional charts.

## 🚀 Quick Start

```bash
# Start container
docker run -d \
  --name internet-monitor \
  -p 8000:8000 \
  syntaxsorcerer7/internet-monitor

# Open web interface
open http://localhost:8000
```

## 📊 Features

### 📈 Three Monitoring Levels
- **📍 Detailed History**: Minute-by-minute recording of all connectivity tests
- **⏰ 24-Hour Overview**: Hourly aggregation with availability percentages  
- **📅 30-Day Overview**: Daily long-term trends for SLA monitoring

### 🎯 Professional Availability Levels
- 🟢 **Excellent** (≥99.9%): Enterprise-grade availability
- 🟡 **Good** (98.0-99.8%): Acceptable performance with occasional interruptions
- 🔴 **Problematic** (<98%): Frequent outages, immediate action required
- 🔵 **No Data**: No measurements available yet

### ⚡ Technical Highlights
- **Real-time Updates**: Automatic chart refresh every 60 seconds
- **Responsive Design**: Optimized for desktop, tablet, and mobile
- **Persistent Storage**: SQLite database with automatic cleanup
- **Multi-Platform**: Supports AMD64 and ARM64 (Raspberry Pi, Apple Silicon)
- **High Performance**: Minimal resource usage through Alpine Linux

## ⚙️ Configuration

All settings are configured via environment variables:

| Variable | Default | Description |
|----------|----------|--------------|
| `CHECK_INTERVAL_SEC` | `20` | Interval between connectivity tests (seconds) |
| `RETENTION_DAYS` | `60` | Data retention period (days) |
| `TEST_URL` | `https://1.1.1.1` | Target URL for connectivity tests |
| `DB_PATH` | `data.db` | Path to SQLite database file |

## 🛠️ Usage

### Standard Configuration
```bash
docker run -d \
  --name internet-monitor \
  -p 8000:8000 \
  syntaxsorcerer7/internet-monitor
```

### Advanced Configuration
```bash
# High-frequency monitoring (every 10 seconds)
docker run -d \
  --name internet-monitor \
  -p 8000:8000 \
  -e CHECK_INTERVAL_SEC=10 \
  -e RETENTION_DAYS=90 \
  syntaxsorcerer7/internet-monitor

# Monitoring different targets
docker run -d --name monitor-google -p 8001:8000 \
  -e TEST_URL=https://google.com \
  syntaxsorcerer7/internet-monitor

docker run -d --name monitor-github -p 8002:8000 \
  -e TEST_URL=https://github.com \
  syntaxsorcerer7/internet-monitor
```

### Persistent Data
```bash
# Store database outside container
docker run -d \
  --name internet-monitor \
  -p 8000:8000 \
  -v $(pwd)/monitor-data:/app \
  syntaxsorcerer7/internet-monitor
```

### Docker Compose
```yaml
version: '3.8'
services:
  internet-monitor:
    image: syntaxsorcerer7/internet-monitor:latest
    container_name: internet-monitor
    ports:
      - "8000:8000"
    environment:
      - CHECK_INTERVAL_SEC=20
      - RETENTION_DAYS=60
      - TEST_URL=https://1.1.1.1
    volumes:
      - ./monitor-data:/app
    restart: unless-stopped
```

## 📊 SLA Reference Table

| Availability | Downtime/Year | Downtime/Month | Downtime/Day | Rating |
|---------------|------------------|-------------------|-----------------|-----------|
| 99.99% | 52.6 minutes | 4.4 minutes | 8.6 seconds | 🟢 Excellent |
| 99.9% | 8.77 hours | 43.8 minutes | 1.44 minutes | 🟢 Excellent |
| 99.5% | 43.8 hours | 3.65 hours | 7.2 minutes | 🟡 Good |
| 99.0% | 87.7 hours | 7.31 hours | 14.4 minutes | 🟡 Good |
| 98.0% | 175 hours | 14.6 hours | 28.8 minutes | 🔴 Problematic |

## 💡 Use Cases

- **🏠 Home Networks**: Monitor DSL/fiber connections
- **🏢 Office Networks**: Document provider outages
- **📋 SLA Monitoring**: Prove availability for contracts
- **🔧 Troubleshooting**: Root cause analysis for connection issues
- **📈 Capacity Planning**: Long-term trend analysis for upgrades

## 🚨 Troubleshooting

### Container won't start
```bash
# Check logs
docker logs internet-monitor

# Check port conflicts
netstat -tulpn | grep :8000
lsof -i :8000
```

### No data visible
- **Wait**: Allow at least 1-2 minutes after startup
- **Network**: Check container network connection
- **URL**: Validate TEST_URL reachability
- **Firewall**: Allow outgoing HTTP connections

### Performance Optimization
```bash
# Reduce memory usage
docker run -d -e RETENTION_DAYS=7 syntaxsorcerer7/internet-monitor

# Higher frequency for critical systems
docker run -d -e CHECK_INTERVAL_SEC=5 syntaxsorcerer7/internet-monitor

# Set resource limits
docker run -d --memory=128m --cpus=0.5 syntaxsorcerer7/internet-monitor
```

## 🏗️ Architecture

- **Backend**: Python Flask with SQLite database
- **Frontend**: Responsive HTML with Chart.js visualizations
- **Container**: Alpine Linux (Python 3.12) for minimal footprint
- **Monitoring**: HTTP requests with 5s timeout for reliable tests
- **Multi-Platform**: Supports AMD64 and ARM64 architectures

## 🔗 Links

- **GitHub Repository**: [SyntaxSorcerer7/internet-check](https://github.com/SyntaxSorcerer7/internet-check)
- **Issues & Support**: [GitHub Issues](https://github.com/SyntaxSorcerer7/internet-check/issues)
- **Docker Hub**: [syntaxsorcerer7/internet-monitor](https://hub.docker.com/r/syntaxsorcerer7/internet-monitor)

## 📝 License

This project is licensed under the **MIT License**.

---

Made with ❤️ for reliable internet monitoring
