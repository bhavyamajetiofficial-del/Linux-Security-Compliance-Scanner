score=0
total=10


#!/bin/bash

echo "=============================="
echo "Linux Security Compliance Scan"
echo "=============================="

echo ""
echo "[+] System Information"
echo "----------------------"

echo "Hostname:"
hostname

echo ""

echo "Operating System:"
cat /etc/os-release | grep PRETTY_NAME

echo ""

echo "Kernel Version:"
uname -r

echo ""

echo "System Uptime:"
uptime -p

echo "Currently logged in user"
whoami



echo ""
echo "[+] User Security Check"
echo "----------------------"

echo ""
echo "All Users:"
cut -d: -f1 /etc/passwd

echo ""
echo "Users with UID 0 (Root Privileges):"
awk -F: '$3 == 0 {print $1}' /etc/passwd

echo ""
echo "Users with Sudo Access:"
getent group sudo





echo ""
echo "[+] Sensitive File Permission Check"
echo "-------------------------------------"

shadow_perm=$(ls -l /etc/shadow | awk '{print $1}')

echo "Permissions for /etc/shadow:"
echo $shadow_perm

if [ "$shadow_perm" = "-rw-r-----" ]; then
    echo "[PASS] /etc/shadow permissions are secure"
else
    echo "[FAIL] /etc/shadow permissions are NOT secure"
fi




echo ""
echo "[+] Network Security Check"
echo "-------------------------------------"

ports=$(ss -tuln | grep LISTEN)

if [ -z "$ports" ]; then
    echo "[PASS] No listening ports detected"
else
    echo "[WARNING] Open ports detected:"
    ss -tuln
fi

echo ""
echo "[+] Running Services Check"
echo "-------------------------------------"

systemctl list-units --type=service --state=running --no-pager


echo ""
echo "[+] Firewall Status Check"
echo "-------------------------------------"

fw_status=$(ufw status | head -n 1)

echo "$fw_status"

if echo "$fw_status" | grep -q "active"; then
    echo "[PASS] Firewall is active"
else
    echo "[FAIL] Firewall is not active"
fi


echo ""
echo "[+] Firewall Rules"
echo "-------------------------------------"

sudo ufw status numbered

echo ""
echo "[+] SSH Security Check"
echo "-------------------------------------"

ssh_root=$(grep "^PermitRootLogin" /etc/ssh/sshd_config)

if echo "$ssh_root" | grep -q "yes"; then
    echo "[FAIL] Root login via SSH is enabled"
else
    echo "[PASS] Root login via SSH is disabled or restricted"
fi

echo ""
echo "[+] SSH Password Authentication Check"
echo "-------------------------------------"

ssh_pass=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config)

if echo "$ssh_pass" | grep -q "yes"; then
    echo "[WARNING] SSH password authentication is enabled"
else
    echo "[PASS] SSH password authentication is disabled"
fi

echo ""
echo "[+] Password Policy Check"
echo "-------------------------------------"

grep PASS_MAX_DAYS /etc/login.defs
grep PASS_MIN_DAYS /etc/login.defs
grep PASS_WARN_AGE /etc/login.defs

echo ""
echo "[+] Password Policy Check"
echo "-------------------------------------"

max_days=$(grep PASS_MAX_DAYS /etc/login.defs | awk '{print $2}')

echo "PASS_MAX_DAYS: $max_days"

if [ "$max_days" -gt 365 ]; then
    echo "[WARNING] Password expiration policy is too long"
else
    echo "[PASS] Password expiration policy is acceptable"
fi


echo ""
echo "[+] System Update Check"
echo "-------------------------------------"

updates=$(apt list --upgradable 2>/dev/null | grep -v Listing)

if [ -z "$updates" ]; then
    echo "[PASS] System is up to date"
else
    echo "[WARNING] Updates are available"
    apt list --upgradable 2>/dev/null
fi


fw_status=$(ufw status | head -n 1)

if echo "$fw_status" | grep -q "active"; then
    echo "[PASS] Firewall is active"
    score=$((score+1))
else
    echo "[FAIL] Firewall is not active"
fi

echo ""
echo "====================================="
echo " Security Compliance Score"
echo "====================================="

echo "Score: $score / $total"
