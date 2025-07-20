#!/bin/bash

# ========================================
# MyNode - Quick Node Health Check
# Author: MyNode Team
# Version: 1.0
# Date: January 2025
# ========================================

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
SERVICE_NAME="redbelly.service"
STATUS_PORT="6539"

print_header() {
    echo -e "${PURPLE}=========================================="
    echo -e "🏥 MyNode - Quick Health Check"
    echo -e "==========================================${NC}\n"
}

print_status() {
    local status=$1
    local message=$2
    
    case $status in
        "ok")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "info")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Check service status
check_service() {
    echo -e "${BLUE}🔍 Checking Redbelly service...${NC}"
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_status "ok" "Service $SERVICE_NAME is active"
        
        # Check uptime
        start_time=$(systemctl show "$SERVICE_NAME" --property=ActiveEnterTimestamp --value)
        if [[ -n "$start_time" ]]; then
            echo -e "   Started: $start_time"
        fi
    else
        print_status "error" "Service $SERVICE_NAME is not active"
        return 1
    fi
}

# Check port
check_port() {
    echo -e "\n${BLUE}🌐 Checking monitoring port...${NC}"
    
    if netstat -tlnp 2>/dev/null | grep -q ":$STATUS_PORT"; then
        print_status "ok" "Port $STATUS_PORT is open and listening"
    else
        print_status "error" "Port $STATUS_PORT is not listening"
        return 1
    fi
}

# Test API
test_api() {
    echo -e "\n${BLUE}🔌 Testing node API...${NC}"
    
    if curl -s --max-time 5 "http://localhost:$STATUS_PORT/status" >/dev/null 2>&1; then
        print_status "ok" "Node API is responding"
        
        # Get basic information
        status_data=$(curl -s --max-time 5 "http://localhost:$STATUS_PORT/status" 2>/dev/null)
        
        if [[ -n "$status_data" ]]; then
            # Check synchronization
            if echo "$status_data" | grep -q '"isRecoveryComplete":true'; then
                print_status "ok" "Node is synchronized"
            else
                print_status "warning" "Node may not be synchronized"
            fi
            
            # Check block
            current_block=$(echo "$status_data" | grep -o '"currentBlock":[0-9]*' | cut -d':' -f2)
            if [[ -n "$current_block" ]]; then
                echo -e "   Current block: $current_block"
            fi
            
            # Check balance
            balance_raw=$(echo "$status_data" | grep -o '"signingAddressBalance":"[^"]*"' | cut -d'"' -f4)
            if [[ -n "$balance_raw" ]]; then
                # Convert from wei to RBNT (assuming 18 decimal places)
                balance=$(echo "scale=2; $balance_raw / 1000000000000000000" | bc -l 2>/dev/null || echo "N/A")
                echo -e "   Balance: $balance RBNT"
                
                # Check if balance is sufficient
                if (( $(echo "$balance >= 500" | bc -l 2>/dev/null || echo "0") )); then
                    print_status "ok" "Balance is sufficient"
                elif (( $(echo "$balance >= 250" | bc -l 2>/dev/null || echo "0") )); then
                    print_status "warning" "Balance is low - consider topping up"
                else
                    print_status "error" "Balance is too low - please top up account"
                fi
            fi
        fi
    else
        print_status "error" "Node API is not responding"
        return 1
    fi
}

# Check resources
check_resources() {
    echo -e "\n${BLUE}💻 Checking system resources...${NC}"
    
    # RAM
    ram_info=$(free | grep Mem)
    ram_total=$(echo $ram_info | awk '{print $2}')
    ram_used=$(echo $ram_info | awk '{print $3}')
    ram_percent=$(( ram_used * 100 / ram_total ))
    
    echo -e "   RAM: $ram_percent%"
    if [[ $ram_percent -gt 80 ]]; then
        print_status "warning" "High RAM usage"
    else
        print_status "ok" "Normal RAM usage"
    fi
    
    # Disk
    disk_usage=$(df / | awk 'NR==2 {print $(NF-1)}' | sed 's/%//')
    echo -e "   Disk: $disk_usage%"
    if [[ $disk_usage -gt 90 ]]; then
        print_status "error" "Critically low disk space"
    elif [[ $disk_usage -gt 80 ]]; then
        print_status "warning" "Low disk space"
    else
        print_status "ok" "Sufficient disk space"
    fi
}

# Check logs
check_logs() {
    echo -e "\n${BLUE}📋 Checking logs for errors...${NC}"
    
    # Check service logs for recent errors
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        error_count=$(journalctl -u "$SERVICE_NAME" --since "1 hour ago" --no-pager | grep -i error | wc -l)
        if [[ $error_count -eq 0 ]]; then
            print_status "ok" "No recent errors in service logs"
        else
            print_status "warning" "Found $error_count error(s) in service logs"
        fi
    fi
    
    # Check application logs if they exist
    if [[ -f "/var/log/redbelly/rbn_logs/rbbc_logs.log" ]]; then
        app_error_count=$(tail -100 /var/log/redbelly/rbn_logs/rbbc_logs.log | strings | grep -i error | wc -l)
        if [[ $app_error_count -eq 0 ]]; then
            print_status "ok" "No recent errors in application logs"
        else
            print_status "warning" "Found $app_error_count error(s) in application logs"
        fi
    else
        print_status "info" "Application log file not found at /var/log/redbelly/rbn_logs/rbbc_logs.log"
    fi
}

# Summary
show_summary() {
    echo -e "\n${PURPLE}=========================================="
    echo -e "📊 Node Health Summary"
    echo -e "==========================================${NC}"
    
    if systemctl is-active --quiet "$SERVICE_NAME" && \
       netstat -tlnp 2>/dev/null | grep -q ":$STATUS_PORT" && \
       curl -s --max-time 5 "http://localhost:$STATUS_PORT/status" >/dev/null 2>&1; then
        
        print_status "ok" "Node appears healthy! 🎉"
        echo -e "\n${GREEN}You can test it at: https://mynody.uk${NC}"
    else
        print_status "warning" "Node needs attention 🔧"
        echo -e "\n${YELLOW}Run full diagnostics: ./diagnose.sh${NC}"
        echo -e "${YELLOW}Or check troubleshooting guide: docs/troubleshooting.md${NC}"
    fi
}

# Check for required tools
check_requirements() {
    local missing=()
    
    command -v curl >/dev/null || missing+=("curl")
    command -v netstat >/dev/null || missing+=("net-tools")
    command -v bc >/dev/null || missing+=("bc")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_status "warning" "Missing tools: ${missing[*]}"
        echo -e "${YELLOW}   Install with: apt install ${missing[*]}${NC}"
        echo
    fi
}

# Main function
main() {
    print_header
    check_requirements
    
    # Run checks
    local exit_code=0
    
    check_service || exit_code=1
    check_port || exit_code=1  
    test_api || exit_code=1
    check_resources
    check_logs
    
    show_summary
    
    exit $exit_code
}

# Run main function
main "$@" 
