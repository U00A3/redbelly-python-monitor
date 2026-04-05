#!/bin/bash

# ========================================
# MyNode - Automated Monitoring Configuration Script
# Author: MyNode Team
# Version: 1.0
# Date: January 2025
# ========================================

set -e  # Stop script on first error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
SERVICE_NAME="redbelly.service"
STATUS_PORT="6539"
PROMETHEUS_ADDR="127.0.0.1"
BACKUP_DIR="/tmp/mynode-backup-$(date +%Y%m%d-%H%M%S)"

# Helper functions
print_header() {
    echo -e "${PURPLE}"
    echo "=========================================="
    echo "🚀 MyNode - Monitoring Configuration"
    echo "=========================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${CYAN}📋 $1${NC}"
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

# Check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        echo "Use: sudo $0"
        exit 1
    fi
}

# Find service file
find_service_file() {
    print_step "Looking for $SERVICE_NAME service file..."
    
    local service_paths=(
        "/etc/systemd/system/$SERVICE_NAME"
        "/lib/systemd/system/$SERVICE_NAME"
        "/usr/lib/systemd/system/$SERVICE_NAME"
    )
    
    for path in "${service_paths[@]}"; do
        if [[ -f "$path" ]]; then
            SERVICE_FILE="$path"
            print_success "Found service file: $SERVICE_FILE"
            return 0
        fi
    done
    
    print_error "Service file $SERVICE_NAME not found"
    print_info "Check if service is installed: systemctl list-unit-files | grep redbelly"
    exit 1
}

# Create backup
create_backup() {
    print_step "Creating backup..."
    
    mkdir -p "$BACKUP_DIR"
    cp "$SERVICE_FILE" "$BACKUP_DIR/"
    
    print_success "Backup created at: $BACKUP_DIR"
    echo -e "${YELLOW}💡 In case of problems, restore: cp $BACKUP_DIR/$(basename $SERVICE_FILE) $SERVICE_FILE${NC}"
}

# Check current configuration
check_current_config() {
    print_step "Checking current configuration..."
    
    if grep -q "statusserver.addr" "$SERVICE_FILE"; then
        print_warning "Monitoring is already configured!"
        echo -e "${YELLOW}Do you want to continue and update the configuration? (y/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_info "Cancelled by user"
            exit 0
        fi
    else
        print_info "Monitoring is not yet configured"
    fi
}

# Configure monitoring
configure_monitoring() {
    print_step "Configuring monitoring parameters..."
    
    # Find ExecStart line
    if ! grep -q "ExecStart=" "$SERVICE_FILE"; then
        print_error "ExecStart line not found in service file"
        exit 1
    fi
    
    # Remove existing monitoring parameters if they exist
    sed -i 's/--statusserver\.addr=[^ ]* //g' "$SERVICE_FILE"
    sed -i 's/--statusserver\.port=[^ ]* //g' "$SERVICE_FILE"
    sed -i 's/--prometheus\.addr=[^ ]* //g' "$SERVICE_FILE"
    
    # Add new monitoring parameters before --mainnet
    sed -i "s|--mainnet|--statusserver.addr=0.0.0.0 --statusserver.port=$STATUS_PORT --prometheus.addr=$PROMETHEUS_ADDR --mainnet|g" "$SERVICE_FILE"
    
    print_success "Monitoring parameters have been added"
}

# Check firewall configuration
check_firewall() {
    print_step "Checking firewall configuration..."
    
    # Check UFW
    if command -v ufw >/dev/null 2>&1; then
        print_info "UFW firewall detected"
        if ufw status | grep -q "Status: active"; then
            print_step "Opening port $STATUS_PORT in UFW..."
            ufw allow "$STATUS_PORT/tcp" >/dev/null 2>&1
            print_success "Port $STATUS_PORT has been opened in UFW"
        else
            print_info "UFW is inactive"
        fi
    # Check firewalld
    elif command -v firewall-cmd >/dev/null 2>&1; then
        print_info "firewalld detected"
        if firewall-cmd --state >/dev/null 2>&1; then
            print_step "Opening port $STATUS_PORT in firewalld..."
            firewall-cmd --permanent --add-port="$STATUS_PORT/tcp" >/dev/null 2>&1
            firewall-cmd --reload >/dev/null 2>&1
            print_success "Port $STATUS_PORT has been opened in firewalld"
        else
            print_info "firewalld is inactive"
        fi
    else
        print_warning "No known firewall detected. Make sure port $STATUS_PORT is open"
    fi
}

# Restart service
restart_service() {
    print_step "Restarting $SERVICE_NAME service..."
    
    # Stop service
    systemctl stop "$SERVICE_NAME"
    print_info "Service stopped"
    
    # Reload systemd configuration
    systemctl daemon-reload
    print_info "systemd configuration reloaded"
    
    # Start service
    systemctl start "$SERVICE_NAME"
    print_info "Service started"
    
    # Check status
    sleep 3
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_success "Service $SERVICE_NAME is running properly"
    else
        print_error "Service $SERVICE_NAME is not running!"
        print_info "Check logs: journalctl -u $SERVICE_NAME --no-pager"
        exit 1
    fi
}

# Test connection
test_connection() {
    print_step "Testing connection to monitor..."
    
    sleep 5  # Give time to start up
    
    # Test local connection
    if curl -s --max-time 10 "http://localhost:$STATUS_PORT/status" >/dev/null 2>&1; then
        print_success "✅ Local monitoring is working!"
        
        # Get node info
        node_info=$(curl -s --max-time 5 "http://localhost:$STATUS_PORT/status" 2>/dev/null)
        
        if [[ -n "$node_info" ]]; then
            # Show basic info
            current_block=$(echo "$node_info" | grep -o '"currentBlock":[0-9]*' | cut -d':' -f2)
            is_synced=$(echo "$node_info" | grep -o '"isRecoveryComplete":[^,]*' | cut -d':' -f2)
            
            if [[ -n "$current_block" ]]; then
                echo -e "   Current block: ${WHITE}$current_block${NC}"
            fi
            
            if [[ "$is_synced" == "true" ]]; then
                echo -e "   Sync status: ${GREEN}✅ Synchronized${NC}"
            else
                echo -e "   Sync status: ${YELLOW}⏳ Synchronizing...${NC}"
            fi
        fi
        
    else
        print_error "❌ Local monitoring is not responding"
        print_info "Check logs: journalctl -u $SERVICE_NAME -n 20"
        return 1
    fi
}

# Show final instructions
show_final_instructions() {
    echo -e "\n${PURPLE}=========================================="
    echo -e "✨ Configuration Complete!"
    echo -e "==========================================${NC}"
    
    print_success "Monitoring has been successfully configured!"
    
    echo -e "\n${WHITE}Next steps:${NC}"
    echo -e "1. Test your node at: ${CYAN}https://mynody.uk${NC}"
    echo -e "2. Enter your server IP address"
    echo -e "3. Monitor your node regularly"
    
    echo -e "\n${WHITE}Useful commands:${NC}"
    echo -e "• Check service status: ${CYAN}systemctl status $SERVICE_NAME${NC}"
    echo -e "• View service logs: ${CYAN}journalctl -u $SERVICE_NAME -f${NC}"
    echo -e "• View node logs: ${CYAN}tail -f /var/log/redbelly/rbn_logs/rbbc_logs.log${NC}"
    echo -e "• Quick health check: ${CYAN}./check-node-health.sh${NC}"
    
    echo -e "\n${WHITE}Troubleshooting:${NC}"
    echo -e "• If issues occur, restore backup: ${CYAN}cp $BACKUP_DIR/$(basename $SERVICE_FILE) $SERVICE_FILE${NC}"
    echo -e "• Check troubleshooting guide: ${CYAN}docs/troubleshooting.md${NC}"
    
    echo -e "\n${GREEN}🎉 Your Redbelly node monitoring is now active!${NC}"
}

# Main execution
main() {
    print_header
    
    # Pre-flight checks
    check_root
    find_service_file
    create_backup
    check_current_config
    
    # Configuration
    configure_monitoring
    check_firewall
    restart_service
    
    # Testing
    if test_connection; then
        show_final_instructions
    else
        print_error "Configuration completed but testing failed"
        print_info "Check the troubleshooting guide or run: ./diagnose.sh"
        exit 1
    fi
    
    echo -e "\n${BLUE}💡 Tip: Bookmark https://mynody.uk for easy monitoring access${NC}"
}

# Error handling
handle_error() {
    print_error "An error occurred during configuration"
    print_info "Backup location: $BACKUP_DIR"
    print_info "Check logs: journalctl -u $SERVICE_NAME --no-pager"
    exit 1
}

# Set error trap
trap handle_error ERR

# Run main function
main "$@" 