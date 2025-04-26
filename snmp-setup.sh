#!/bin/bash

echo "-------------------------------------------"
echo " SNMP Setup Script - Manager or Agent"
echo "-------------------------------------------"
echo ""

# Prompt user
read -p "Is this server going to be an SNMP (agent/manager)? " role

# Convert to lowercase
role=$(echo "$role" | tr '[:upper:]' '[:lower:]')

if [[ "$role" == "agent" ]]; then
    echo ""
    echo "Setting up SNMP Agent..."
    sudo apt update
    sudo apt install snmp snmpd -y

    # Backup snmpd.conf
    echo "Backing up existing snmpd.conf to snmpd.conf.bak..."
    sudo cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bak

    # Configure snmpd.conf
    echo "Configuring snmpd.conf..."
    sudo sed -i 's/^agentAddress.*/agentAddress udp:161/' /etc/snmp/snmpd.conf

    # Check if 'rocommunity public' exists, else add it
    if ! grep -q '^rocommunity public' /etc/snmp/snmpd.conf; then
        echo "Adding 'rocommunity public' to snmpd.conf..."
        echo "rocommunity public" | sudo tee -a /etc/snmp/snmpd.conf
    fi

    # Restart service
    echo "Restarting snmpd service..."
    sudo systemctl restart snmpd

    # Enable firewall rule (optional if ufw enabled)
    if sudo ufw status | grep -q "inactive"; then
        echo "Firewall is inactive. No changes made to firewall."
    else
        echo "Allowing UDP 161 through firewall..."
        sudo ufw allow 161/udp
    fi

    echo ""
    echo "✅ SNMP Agent setup completed!"

elif [[ "$role" == "manager" ]]; then
    echo ""
    echo "Setting up SNMP Manager..."
    sudo apt update
    sudo apt install snmp -y

    # Ask for Agent IP
    read -p "Enter the IP address of the SNMP Agent you want to test against: " agent_ip

    echo ""
    echo "Testing SNMP connectivity to $agent_ip..."

    # Run a test
    snmpwalk -v2c -c public "$agent_ip" 1.3.6.1.2.1.1.1.0

    echo ""
    echo "✅ SNMP Manager setup and test completed!"

else
    echo "❌ Invalid input. Please type 'agent' or 'manager'. Exiting."
    exit 1
fi
