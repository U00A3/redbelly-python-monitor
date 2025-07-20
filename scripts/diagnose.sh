#!/bin/bash

# ========================================
# MyNode - Node Diagnostic Script
# Author: MyNode Team
# Version: 1.0
# Date: January 2025
# ========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
SERVICE_NAME="redbelly.service"
STATUS_PORT="6539"
LOG_FILE="/tmp/mynode-diagnostic-$(date +%Y%m%d-%H%M%S).log"

print_header() {
    echo -e "${PURPLE}"
    echo "=========================================="
    echo "🔍 MyNode - Node Diagnostics"
    echo "=========================================="
    echo -e "${NC}"
}

print_section() {
    echo -e "\n${CYAN}📋 $1${NC}"
    echo "----------------------------------------"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Log to file
log_to_file() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# System information
check_system_info() {
    print_section "System Information"
    
    echo -e "${WHITE}Hostname:${NC} $(hostname)"
    echo -e "${WHITE}OS:${NC} $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    echo -e "${WHITE}Kernel:${NC} $(uname -r)"
    echo -e "${WHITE}Uptime:${NC} $(uptime -p)"
    echo -e "${WHITE}Date/Time:${NC} $(date)"
    
    # System resources
    echo -e "\n${WHITE}Resources:${NC}"
    echo -e "  CPU: $(nproc) cores"
    echo -e "  RAM: $(free -h | awk '/^Mem:/ {print $2}' | sed 's/i$//')"
    echo -e "  Free space: $(df -h / | awk 'NR==2 {print $4}')"
    
    log_to_file "System info checked"
}

# Redbelly service status
check_service_status() {
    print_section "Redbelly Service Status"
    
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        print_success "Service $SERVICE_NAME is enabled"
    else
        print_warning "Service $SERVICE_NAME is not enabled"
    fi
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_success "Service $SERVICE_NAME is active"
        
        # Check uptime
        uptime_sec=$(systemctl show "$SERVICE_NAME" --property=ActiveEnterTimestamp --value)
        if [[ -n "$uptime_sec" ]]; then
            echo -e "${WHITE}Running since:${NC} $uptime_sec"
        fi
    else
        print_error "Service $SERVICE_NAME is not active"
        
        # Check last error
        if systemctl is-failed --quiet "$SERVICE_NAME"; then
            print_error "Service status: FAILED"
            echo -e "${YELLOW}Recent errors:${NC}"
            journalctl -u "$SERVICE_NAME" --since "1 hour ago" | grep -i error | tail -5
        fi
    fi
    
    log_to_file "Service status checked"
}

# Service configuration
check_service_config() {
    print_section "Service Configuration"
    
    local service_file
    if [[ -f "/etc/systemd/system/$SERVICE_NAME" ]]; then
        service_file="/etc/systemd/system/$SERVICE_NAME"
    elif [[ -f "/lib/systemd/system/$SERVICE_NAME" ]]; then
        service_file="/lib/systemd/system/$SERVICE_NAME"
    else
        print_error "Service file $SERVICE_NAME not found"
        return 1
    fi
    
    print_info "Service file: $service_file"
    
    # Check monitoring parameters
    if grep -q "statusserver.addr" "$service_file"; then
        print_success "Parameter statusserver.addr configured"
        statusserver_addr=$(grep -o "statusserver.addr=[^ ]*" "$service_file" | cut -d'=' -f2)
        echo -e "  Address: ${WHITE}$statusserver_addr${NC}"
    else
        print_error "Parameter statusserver.addr NOT configured"
    fi
    
    if grep -q "statusserver.port" "$service_file"; then
        print_success "Parameter statusserver.port configured"
        statusserver_port=$(grep -o "statusserver.port=[^ ]*" "$service_file" | cut -d'=' -f2)
        echo -e "  Port: ${WHITE}$statusserver_port${NC}"
    else
        print_error "Parameter statusserver.port NOT configured"
    fi
    
    if grep -q "prometheus.addr" "$service_file"; then
        print_success "Parameter prometheus.addr configured"
        prometheus_addr=$(grep -o "prometheus.addr=[^ ]*" "$service_file" | cut -d'=' -f2)
        echo -e "  Prometheus: ${WHITE}$prometheus_addr${NC}"
    else
        print_error "Parameter prometheus.addr NOT configured"
    fi
    
    log_to_file "Service config checked"
}

# Network status
check_network() {
    print_section "Network Status"
    
    # Check if port is open
    if netstat -tlnp 2>/dev/null | grep -q ":$STATUS_PORT"; then
        print_success "Port $STATUS_PORT is open and listening"
        
        # Show listening process
        process=$(netstat -tlnp 2>/dev/null | grep ":$STATUS_PORT" | awk '{print $7}' | head -1)
        if [[ -n "$process" ]]; then
            echo -e "  Process: ${WHITE}$process${NC}"
        fi
    else
        print_error "Port $STATUS_PORT is not open"
        
        # Check if any redbelly port is listening
        redbelly_ports=$(netstat -tlnp 2>/dev/null | grep redbelly | awk '{print $4}' | cut -d':' -f2)
        if [[ -n "$redbelly_ports" ]]; then
            print_info "Other Redbelly ports: $redbelly_ports"
        fi
    fi
    
    # Test local connection
    print_info "Testing local connection..."
    if curl -s --max-time 5 "http://localhost:$STATUS_PORT/status" >/dev/null 2>&1; then
        print_success "✅ Status endpoint responds"
    else
        print_error "❌ Status endpoint not responding"
    fi
    
    if curl -s --max-time 5 "http://localhost:$STATUS_PORT/metrics" >/dev/null 2>&1; then
        print_success "✅ Metrics endpoint responds"
    else
        print_warning "⚠️  Metrics endpoint may not work"
    fi
    
    log_to_file "Network status checked"
}

# Firewall
check_firewall() {
    print_section "Firewall Configuration"
    
    # UFW
    if command -v ufw >/dev/null 2>&1; then
        print_info "UFW detected"
        ufw_status=$(ufw status 2>/dev/null)
        
        if echo "$ufw_status" | grep -q "Status: active"; then
            print_info "UFW is active"
            
            if echo "$ufw_status" | grep -q "$STATUS_PORT"; then
                print_success "Port $STATUS_PORT is allowed in UFW"
            else
                print_warning "Port $STATUS_PORT may be blocked by UFW"
                echo -e "  ${YELLOW}Fix: sudo ufw allow $STATUS_PORT/tcp${NC}"
            fi
        else
            print_info "UFW is inactive"
        fi
    fi
    
    # Firewalld
    if command -v firewall-cmd >/dev/null 2>&1; then
        print_info "firewalld detected"
        
        if firewall-cmd --state >/dev/null 2>&1; then
            print_info "firewalld is active"
            
            if firewall-cmd --list-ports | grep -q "$STATUS_PORT"; then
                print_success "Port $STATUS_PORT is allowed in firewalld"
            else
                print_warning "Port $STATUS_PORT may be blocked by firewalld"
                echo -e "  ${YELLOW}Fix: sudo firewall-cmd --permanent --add-port=$STATUS_PORT/tcp && sudo firewall-cmd --reload${NC}"
            fi
        else
            print_info "firewalld is inactive"
        fi
    fi
    
    # Iptables
    if command -v iptables >/dev/null 2>&1; then
        print_info "iptables detected"
        
        if iptables -L INPUT -n | grep -q "$STATUS_PORT"; then
            print_success "Port $STATUS_PORT found in iptables rules"
        else
            print_warning "Port $STATUS_PORT not found in iptables rules"
        fi
    fi
    
    log_to_file "Firewall checked"
}

# Node API test
check_node_api() {
    print_section "Node API Test"
    
    if curl -s --max-time 10 "http://localhost:$STATUS_PORT/status" >/dev/null 2>&1; then
        print_success "Node API is responding"
        
        # Get detailed node information
        api_data=$(curl -s --max-time 10 "http://localhost:$STATUS_PORT/status" 2>/dev/null)
        
        if [[ -n "$api_data" ]]; then
            # Parse key information
            current_block=$(echo "$api_data" | grep -o '"currentBlock":[0-9]*' | cut -d':' -f2)
            is_synced=$(echo "$api_data" | grep -o '"isRecoveryComplete":[^,]*' | cut -d':' -f2)
            signing_address=$(echo "$api_data" | grep -o '"signingAddress":"[^"]*"' | cut -d'"' -f4)
            balance_raw=$(echo "$api_data" | grep -o '"signingAddressBalance":"[^"]*"' | cut -d'"' -f4)
            governor_count=$(echo "$api_data" | grep -o '"governorCount":[0-9]*' | cut -d':' -f2)
            
            echo -e "\n${WHITE}Node Information:${NC}"
            
            if [[ -n "$current_block" ]]; then
                echo -e "  Current block: ${WHITE}$current_block${NC}"
            fi
            
            if [[ "$is_synced" == "true" ]]; then
                echo -e "  Sync status: ${GREEN}✅ Synchronized${NC}"
            elif [[ "$is_synced" == "false" ]]; then
                echo -e "  Sync status: ${YELLOW}⏳ Synchronizing...${NC}"
            fi
            
            if [[ -n "$signing_address" ]]; then
                echo -e "  Signing address: ${WHITE}${signing_address:0:10}...${signing_address: -10}${NC}"
            fi
            
            if [[ -n "$balance_raw" && "$balance_raw" != "0x0" ]]; then
                # Convert balance from wei to RBNT
                balance=$(echo "scale=2; $balance_raw / 1000000000000000000" | bc -l 2>/dev/null || echo "N/A")
                echo -e "  Balance: ${WHITE}$balance RBNT${NC}"
                
                # Balance status
                if (( $(echo "$balance >= 500" | bc -l 2>/dev/null || echo "0") )); then
                    echo -e "  Balance status: ${GREEN}✅ Sufficient${NC}"
                elif (( $(echo "$balance >= 250" | bc -l 2>/dev/null || echo "0") )); then
                    echo -e "  Balance status: ${YELLOW}⚠️  Low${NC}"
                else
                    echo -e "  Balance status: ${RED}❌ Too low${NC}"
                fi
            fi
            
            if [[ -n "$governor_count" ]]; then
                echo -e "  Network governors: ${WHITE}$governor_count${NC}"
            fi
        fi
    else
        print_error "Node API is not responding"
        
        # Additional troubleshooting info
        print_info "Troubleshooting steps:"
        echo -e "  1. Check if service is running: ${WHITE}systemctl status $SERVICE_NAME${NC}"
        echo -e "  2. Check if port is listening: ${WHITE}netstat -tlnp | grep $STATUS_PORT${NC}"
        echo -e "  3. Check service logs: ${WHITE}journalctl -u $SERVICE_NAME -n 20${NC}"
    fi
    
    log_to_file "Node API checked"
}

# Performance check
check_performance() {
    print_section "Performance Metrics"
    
    # CPU usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    echo -e "${WHITE}CPU Usage:${NC} $cpu_usage"
    
    # Memory usage
    memory_info=$(free -h)
    memory_used=$(echo "$memory_info" | awk '/^Mem:/ {print $3}')
    memory_total=$(echo "$memory_info" | awk '/^Mem:/ {print $2}')
    echo -e "${WHITE}Memory:${NC} $memory_used / $memory_total"
    
    # Disk usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    disk_free=$(df -h / | awk 'NR==2 {print $4}')
    echo -e "${WHITE}Disk:${NC} $disk_usage used, $disk_free free"
    
    # Load average
    load_avg=$(uptime | awk -F'load average:' '{print $2}')
    echo -e "${WHITE}Load average:${NC}$load_avg"
    
    # Check if redbelly process is running
    if pgrep -f redbelly >/dev/null; then
        redbelly_pid=$(pgrep -f redbelly)
        redbelly_cpu=$(ps -p $redbelly_pid -o %cpu --no-headers)
        redbelly_mem=$(ps -p $redbelly_pid -o %mem --no-headers)
        echo -e "${WHITE}Redbelly process:${NC} PID $redbelly_pid, CPU ${redbelly_cpu}%, MEM ${redbelly_mem}%"
    else
        print_warning "Redbelly process not found"
    fi
    
    log_to_file "Performance checked"
}

# Log analysis
check_logs() {
    print_section "Log Analysis"
    
    # Service logs
    print_info "Checking service logs..."
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        # Recent errors in service logs
        error_count=$(journalctl -u "$SERVICE_NAME" --since "1 hour ago" --no-pager | grep -i error | wc -l)
        
        if [[ $error_count -eq 0 ]]; then
            print_success "No recent errors in service logs"
        else
            print_warning "Found $error_count error(s) in service logs"
            echo -e "${YELLOW}Recent errors:${NC}"
            journalctl -u "$SERVICE_NAME" --since "1 hour ago" --no-pager | grep -i error | tail -3
        fi
        
        # Recent warnings
        warning_count=$(journalctl -u "$SERVICE_NAME" --since "1 hour ago" --no-pager | grep -i warning | wc -l)
        if [[ $warning_count -gt 0 ]]; then
            print_warning "Found $warning_count warning(s) in service logs"
        fi
    fi
    
    # Application logs
    print_info "Checking application logs..."
    
    if [[ -f "/var/log/redbelly/rbn_logs/rbbc_logs.log" ]]; then
        print_success "Application log file found"
        
        # Check recent errors in application logs
        app_errors=$(tail -100 /var/log/redbelly/rbn_logs/rbbc_logs.log | strings | grep -i error | wc -l)
        
        if [[ $app_errors -eq 0 ]]; then
            print_success "No recent errors in application logs"
        else
            print_warning "Found $app_errors error(s) in application logs"
            echo -e "${YELLOW}Recent application errors:${NC}"
            tail -100 /var/log/redbelly/rbn_logs/rbbc_logs.log | strings | grep -i error | tail -3
        fi
        
        # Log file size
        log_size=$(du -h /var/log/redbelly/rbn_logs/rbbc_logs.log | cut -f1)
        echo -e "  Log file size: ${WHITE}$log_size${NC}"
        
    else
        print_warning "Application log file not found at /var/log/redbelly/rbn_logs/rbbc_logs.log"
        
        # Check if logs directory exists
        if [[ -d "/var/log/redbelly/rbn_logs" ]]; then
            print_info "Log directory exists, checking for other log files..."
            ls -la /var/log/redbelly/rbn_logs/
        else
            print_warning "Log directory /var/log/redbelly/rbn_logs does not exist"
        fi
    fi
    
    log_to_file "Logs analyzed"
}

# Generate recommendations
generate_recommendations() {
    print_section "Recommendations"
    
    local recommendations=()
    
    # Check if service is running
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        recommendations+=("🔧 Start the Redbelly service: sudo systemctl start $SERVICE_NAME")
    fi
    
    # Check if monitoring is configured
    local service_file="/etc/systemd/system/$SERVICE_NAME"
    if [[ -f "$service_file" ]] && ! grep -q "statusserver.addr" "$service_file"; then
        recommendations+=("⚙️  Configure monitoring: run ./setup-monitoring.sh")
    fi
    
    # Check if port is open
    if ! netstat -tlnp 2>/dev/null | grep -q ":$STATUS_PORT"; then
        recommendations+=("🌐 Port $STATUS_PORT is not listening - check service configuration")
    fi
    
    # Check firewall
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        if ! ufw status | grep -q "$STATUS_PORT"; then
            recommendations+=("🔥 Open port in UFW: sudo ufw allow $STATUS_PORT/tcp")
        fi
    fi
    
    # Display recommendations
    if [[ ${#recommendations[@]} -eq 0 ]]; then
        print_success "No specific recommendations - node appears to be configured correctly!"
    else
        print_info "Action items:"
        for rec in "${recommendations[@]}"; do
            echo -e "  $rec"
        done
    fi
}

# Save diagnostic report
save_diagnostic_report() {
    print_section "Diagnostic Report"
    
    {
        echo "MyNode Diagnostic Report"
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo "========================================"
        echo
        
        echo "SYSTEM INFO:"
        uname -a
        grep PRETTY_NAME /etc/os-release
        echo
        
        echo "SERVICE STATUS:"
        systemctl status "$SERVICE_NAME" --no-pager
        echo
        
        echo "NETWORK:"
        netstat -tlnp | grep -E "(redbelly|$STATUS_PORT)"
        echo
        
        echo "RECENT SERVICE LOGS:"
        journalctl -u "$SERVICE_NAME" --since "1 hour ago" --no-pager | tail -20
        echo
        
        if [[ -f "/var/log/redbelly/rbn_logs/rbbc_logs.log" ]]; then
            echo "RECENT APPLICATION LOGS:"
            tail -20 /var/log/redbelly/rbn_logs/rbbc_logs.log | strings
            echo
        fi
        
        echo "DISK USAGE:"
        df -h
        echo
        
        echo "MEMORY USAGE:"
        free -h
        echo
        
    } > "$LOG_FILE"
    
    print_success "Diagnostic report saved to: $LOG_FILE"
    echo -e "${BLUE}💡 Include this file when asking for help${NC}"
}

# Main function
main() {
    print_header
    
    echo -e "${BLUE}Starting comprehensive node diagnostics...${NC}\n"
    
    # Run all checks
    check_system_info
    check_service_status
    check_service_config
    check_network
    check_firewall
    check_node_api
    check_performance
    check_logs
    generate_recommendations
    save_diagnostic_report
    
    echo -e "\n${PURPLE}=========================================="
    echo -e "🏁 Diagnostic Complete"
    echo -e "==========================================${NC}"
    
    print_info "Diagnostic report: $LOG_FILE"
    print_info "For support, visit: https://github.com/U00A3/mynode/issues"
    
    echo -e "\n${BLUE}💡 Quick commands for further investigation:${NC}"
    echo -e "• Service status: ${WHITE}systemctl status $SERVICE_NAME${NC}"
    echo -e "• Service logs: ${WHITE}journalctl -u $SERVICE_NAME -f${NC}"
    echo -e "• Application logs: ${WHITE}tail -f /var/log/redbelly/rbn_logs/rbbc_logs.log${NC}"
    echo -e "• Quick health: ${WHITE}./check-node-health.sh${NC}"
    echo -e "• Test monitoring: ${WHITE}curl http://localhost:$STATUS_PORT/status${NC}"
}

# Run main function
main "$@" 
