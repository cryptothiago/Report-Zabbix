#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
LBLUE='\033[1;34m'
NC='\033[0m' # No Color
host_name=$(hostname -f)

#checkLastCommand() {
#  COMMAND=$(fc -ln -1 | tr -ds '\t' '')
#  RETURN=$1
  #  echo ${GREEN}Notify USER OK${NC}
  #  else
#  if [ ! $? -eq $RETURN ]; then
#	  echo ${RED}FAIL - $COMMAND${NC}
#  fi
#}

#Change logout time for ssh
echo -e ${GREEN} "Start Hardening" ${NC}

#Configure Locale
echo -e ${LBLUE} "Configuring Bash LOCALE" ${NC}
grep 'LANG=en_US.utf-8' /etc/environment && grep 'LANG=en_US.utf-8' /etc/environment
lc_is_there=$(echo $?)
awk -v line='LANG=en_US.utf-8' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/environment
awk -v line='LC_ALL=en_US.utf-8' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/environment
if [[ $lc_is_there -ne 0 ]]; then
  echo "Exit your shell and execute the script again!" && exit
fi

#BASH HISTORY
echo -e ${LBLUE} "Bash history" ${NC}
echo >> /etc/profile
awk -v line='HISTTIMEFORMAT="%F %T "' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/profile

# Setting up NTP
echo -e ${LBLUE} "Install/Setup up NTP" ${NC}
systemctl list-units -a ntp* | grep "0 loaded units listed." > /dev/null
ntp_is_loaded=$(echo $?)
if [ $ntp_is_loaded -eq 0 ]; then
  apt install ntp -y
  cp --preserve /etc/ntp.conf /etc/ntp.conf.$(date +"%Y%m%d%H%M%S")
  sed -i -r -e "s/^((server|pool).*)/# \1         # commented by $(whoami) on $(date +"%Y-%m-%d @ %H:%M:%S")/" /etc/ntp.conf
  echo -e "\npool pool.ntp.org iburst         # added by $(whoami) on $(date +"%Y-%m-%d @ %H:%M:%S")" | tee -a /etc/ntp.conf
  systemctl restart ntp
fi

echo -e ${LBLUE} "Install necessary init softwares" ${NC}
echo -e ${LBLUE} "  |__> tcpd" ${NC}
echo -e ${LBLUE} "  |__> haveged" ${NC}
echo -e ${LBLUE} "  |__> libpam-pwquality" ${NC}
echo -e ${LBLUE} "  |__> auditd" ${NC}
apt-get install tcpd haveged libpam-pwquality auditd -y

# Installing Debian base packages
echo -e ${LBLUE} "Install Debian base packages" ${NC}
for pkg in $(cat pkg-mgt/debian-std-pkgs.txt); do
  apt-get install $pkg -y
done

# Removing Useless Packages and services
echo -e ${LBLUE} "Remove Useless Packages and services" ${NC}
apt-get remove --purge rsync -y
apt autoremove -y

# Ensure packet redirect sending is disabled 
echo -e ${LBLUE} "Ensure packet redirect sending is disabled" ${NC}
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.default.send_redirects=0
sysctl -w net.ipv4.route.flush=1

# Ensure source routed packets are not accepted
echo -e ${LBLUE} "Ensure source routed packets are not accepted" ${NC}
sysctl -w net.ipv4.conf.all.accept_source_route=0 
sysctl -w net.ipv4.conf.default.accept_source_route=0 
sysctl -w net.ipv4.route.flush=1

# Ensure ICMP redirects are not accepted 
echo -e ${LBLUE} "Ensure ICMP redirects are not accepted" ${NC}
sysctl -w net.ipv4.conf.all.accept_redirects=0 
sysctl -w net.ipv4.conf.default.accept_redirects=0 
sysctl -w net.ipv4.route.flush=1

# Ensure secure ICMP redirects are not accepted
echo -e ${LBLUE} "Ensure secure ICMP redirects are not accepted" ${NC}
sysctl -w net.ipv4.conf.all.secure_redirects=0 
sysctl -w net.ipv4.conf.default.secure_redirects=0 
sysctl -w net.ipv4.route.flush=1

# Ensure suspicious packets are logged 
echo -e ${LBLUE} "Ensure suspicious packets are logged" ${NC}
sysctl -w net.ipv4.conf.all.log_martians=1 
sysctl -w net.ipv4.conf.default.log_martians=1 
sysctl -w net.ipv4.route.flush=1

# Ensure broadcast ICMP requests are ignored 
echo -e ${LBLUE} "Ensure broadcast ICMP requests are ignored" ${NC}
sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1 
sysctl -w net.ipv4.route.flush=1

# Ensure bogus ICMP responses are ignored
echo -e ${LBLUE} "Ensure bogus ICMP responses are ignored" ${NC}
sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1 
sysctl -w net.ipv4.route.flush=1

# Ensure Reverse Path Filtering is enabled
echo -e ${LBLUE} "Ensure Reverse Path Filtering is enabled" ${NC}
sysctl -w net.ipv4.conf.all.rp_filter=1 
sysctl -w net.ipv4.conf.default.rp_filter=1 
sysctl -w net.ipv4.route.flush=1

# Ensure TCP SYN Cookies is enabled
echo -e ${LBLUE} "Ensure TCP SYN Cookies is enabled" ${NC}
sysctl -w net.ipv4.tcp_syncookies=1 
sysctl -w net.ipv4.route.flush=1

# Ensure IPv6 router advertisements are not accepted
echo -e ${LBLUE} "Ensure IPv6 router advertisements are not accepted" ${NC}
sysctl -w net.ipv6.conf.all.accept_ra=0 
sysctl -w net.ipv6.conf.default.accept_ra=0 
sysctl -w net.ipv6.route.flush=1

# Ensure IPv6 redirects are not accepted
echo -e ${LBLUE} "Ensure IPv6 redirects are not accepted" ${NC}
sysctl -w net.ipv6.conf.all.accept_redirects=0 
sysctl -w net.ipv6.conf.default.accept_redirects=0 
sysctl -w net.ipv6.route.flush=1

# Change TTL response
sysctl -w net.ipv4.ip_default_ttl=128

# Ensure IPv6 is disabled
echo -e ${LBLUE} "Ensure IPv6 is disabled" ${NC}
sed -i '/GRUB_CMDLINE_LINUX[^\n]*/,$!b;//{x;//p;g};//!H;$!d;x;s//&\nGRUB_CMDLINE_LINUX=\"ipv6\.disable=1\"/' /etc/default/grub
update-grub

# TCP WRAPPERS
# Ensure TCP Wrappers is installed
echo -e ${LBLUE} "Ensure TCP Wrappers is installed" ${NC}

# UNCOMMON NETWORK PROTOCOLS
# Ensure /etc/modproble.d/CIS.conf exists
echo -e ${LBLUE} "Ensure /etc/modproble.d/CIS.conf exists" ${NC}
if [[ ! -f "/etc/modprobe.d/CIS.conf" ]]; then
    touch /etc/modprobe.d/CIS.conf
fi

# ensure DCCP, SCTP, RDS and TIPC are disabled
echo -e ${LBLUE} "Ensure DCCP, SCTP, RDS and TIPC are disabled" ${NC}
awk -v line='install dccp /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf
awk -v line='install sctp /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf
awk -v line='install rds /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf
awk -v line='install tipc /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf

# Ensure rsyslog Service is enabled 
echo -e ${LBLUE} "Ensure rsyslog Service is enabled" ${NC}
systemctl enable rsyslog

# Entropy config
echo -e ${LBLUE} "Entropy config" ${NC}
systemctl enable haveged
echo "1024" > /proc/sys/kernel/random/write_wakeup_threshold
haveged -w 1024

# Ensure mounting of cramfs filesystems is disabled
echo -e ${LBLUE} "Ensure mounting of cramfs filesystems is disabled" ${NC}
awk -v line='install cramfs /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf

# Ensure mounting of freevxfs filesystems is disabled
echo -e ${LBLUE} "Ensure mounting of freevxfs filesystems is disabled" ${NC}
awk -v line='install freevxfs /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf

# Ensure mounting of jffs2 filesystems is disabled
echo -e ${LBLUE} "Ensure mounting of jffs2 filesystems is disabled" ${NC}
awk -v line='install jffs2 /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf

# Ensure mounting of hfs filesystems is disabled
echo -e ${LBLUE} "Ensure mounting of hfs filesystems is disabled" ${NC}
awk -v line='install hfs /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf

# Ensure mounting of hfsplus filesystems is disabled
echo -e ${LBLUE} "Ensure mounting of hfsplus filesystems is disabled" ${NC}
awk -v line='install hfsplus /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf

# Ensure mounting of hfsplus filesystems is disabled
echo -e ${LBLUE} "Ensure mounting of hfsplus filesystems is disabled" ${NC}
awk -v line='install hfsplus /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf

# Ensure mounting of squashfs filesystems is disabled
echo -e ${LBLUE} "Ensure mounting of squashfs filesystems is disabled" ${NC}
awk -v line='install squashfs /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf

# Ensure mounting of udf filesystems is disabled
echo -e ${LBLUE} "Ensure mounting of udf filesystems is disabled" ${NC}
awk -v line='install udf /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf

# Ensure mounting of FAT filesystems is disabled
echo -e ${LBLUE} "Ensure mounting of FAT filesystems is disabled" ${NC}
awk -v line='install vfat /bin/true' 'FNR==NR && line==$0{f=1; exit} END{if (!f) print line >> FILENAME}' /etc/modprobe.d/CIS.conf

# Disable Automounting
echo -e ${LBLUE} "Disable Automounting" ${NC}
systemctl disable autofs 2>/dev/null || echo "autofs is already disabled/uninstalled"

echo -e ${LBLUE} "Firewall Configuration:" ${NC}
iptables -F
iptables -L
iptables -X

# Ensure default deny firewall policy
echo -e ${LBLUE} "Ensure default deny firewall policy" ${NC}
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# Ensure loopback traffic is configured 
echo -e ${LBLUE} "Ensure loopback traffic is configured" ${NC}
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -s 127.0.0.0/8 -j DROP

# Ensure outbound and established connections are configured
echo -e ${LBLUE} "Ensure outbound and established connections are configured" ${NC}
iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT 
iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT 
iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT 
iptables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT 
iptables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT 
iptables -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT

# Ensure firewall rules exist for all open ports 
echo -e ${LBLUE} "Ensure firewall rules exist for all open ports" ${NC}
iptables -A INPUT -p tcp --dport 1922 -m state --state NEW -j ACCEPT

# Save Iptables roles
echo -e ${LBLUE} "Save Iptables Rules" ${NC}
iptables-save

# Ensure SE Linux is installed
echo -e ${LBLUE} "Ensure SE Linux is installed" ${NC}
apt install selinux-basics selinux-policy-default -y

# Ensure the SELinux state is enforcing 
echo -e ${LBLUE} "Ensure the SELinux state is enforcing" ${NC}
sed -i '/^SELINUX=*/c\SELINUX=enforcing' /etc/selinux/config
sed -i '/^SELINUXTYPE=*/c\SELINUXTYPE=mls' /etc/selinux/config

# Sudoers wheel
echo -e ${LBLUE} "Change SUDO to WHEEL in sudoers" ${NC}
groupadd wheel
chmod u+w /etc/sudoers
sed -i 's/^\%sudo/\%wheel/g' /etc/sudoers

# Ensure no file is unowned
echo -e ${LBLUE} "Ensure no file is unowned" ${NC}
for FILE in $(df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nouser); do
  chown root $FILE
done

# Ensure no ungrouped files or directories 
echo -e ${LBLUE} "Ensure no ungrouped files or directories" ${NC}
for FILE in $(df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nogroup); do
  chgrp root $FILE
done

for FILE in $(df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nouser); do
  if [[ -L "$FILE" ]]; then
    POINT=$(readlink -f $FILE)
    rm -rf $FILE
    ln -s $POINT $FILE
  fi
done

# Ensure no world writable files exist
echo -e ${LBLUE} "Ensure no world writable files exist" ${NC}
for FILE in $(df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -type f -perm -0002); do
  chmod o-w $FILE
done

# Install libpam-pwquality
echo -e ${LBLUE} "Install libpam-pwquality" ${NC}
sed -i '/*pam_pwquality.so retry=2$/c\password	requisite			pam_pwquality.so try_first_pass retry=2' /etc/pam.d/common-password
sed -i 's/\# minlen = 8/minlen = 16/g' /etc/security/pwquality.conf
sed -i 's/\# dcredit = 0/dcredit = -1/g' /etc/security/pwquality.conf
sed -i 's/\# lcredit = 0/lcredit = -1/g' /etc/security/pwquality.conf
sed -i 's/\# ucredit = 0/ucredit = -1/g' /etc/security/pwquality.conf
sed -i 's/\# ocredit = 0/ocredit = -1/g' /etc/security/pwquality.conf

# limit SU cmd only to wheel group
echo -e ${LBLUE} "limit SU cmd only to wheel group" ${NC}
sed -i '/SU_WHEEL_ONLY/c\SU_WHEEL_ONLY    yes' /etc/login.defs

# Configure /etc/pam.d/sudo
echo -e ${LBLUE} "Configure /etc/pam.d/sudo" ${NC}
cat <<EOF > /etc/pam.d/sudo
auth      required      pam_tally2.so onerr=fail deny=6
auth      include       common-auth
account   required      pam_tally2.so
account   include       common-auth
password  include       common-auth
session   optional      pam_keyinit.so
session   required      pam_limits.so
EOF

# Restricting USERS browsing through filesystem
#echo -e ${LBLUE} "Restricting USERS browsing through /opt" ${NC}
#find /opt -type d -exec chmod o-x {} \;
#echo -e ${LBLUE} "Restricting USERS browsing through /var" ${NC}
#find /var -type d -exec chmod o-x {} \;

# Restricting compilers from non root users
echo -e ${LBLUE} "Restricting compilers from non root users" ${NC}
chmod o-xwr /usr/bin/as /usr/bin/g++ /usr/bin/gcc /usr/bin/nasm /usr/bin/x86_64-linux-gnu-as /usr/bin/g++-6 /usr/bin/gcc-6 /usr/bin/x86_64-linux-gnu-g++-6 /usr/bin/x86_64-linux-gnu-gcc-6 2>/dev/null

# Ensure auditd service is enabled
echo -e ${LBLUE} "Ensure auditd service is enabled" ${NC}
systemctl enable auditd

# Ensure system is disabled when audit logs are full
echo -e ${LBLUE} "Ensure system is disabled when audit logs are full" ${NC}
sed -i '/^space_left_action = */c\space_left_action = email' /etc/audit/auditd.conf
sed -i '/^admin_space_left_action = */c\admin_space_left_action = halt' /etc/audit/auditd.conf

# Ensure audit logs are not automatically deleted
echo -e ${LBLUE} "Ensure audit logs are not automatically deleted" ${NC}
sed -i '/GRUB_CMDLINE_LINUX[^\n]*/,$!b;//{x;//p;g};//!H;$!d;x;s//&\nGRUB_CMDLINE_LINUX=\"audit=1\"/' /etc/default/grub
update-grub

#backup and overwrite sshd_config
echo -e ${LBLUE} "Backup /etc/ssh/sshd_config" ${NC}
cp --preserve /etc/ssh/sshd_config /etc/ssh/sshd_config.$(date +"%Y%m%d%H%M%S")
yes| cp ssh/sshd_config /etc/ssh/sshd_config

#create a ssh group user
echo -e ${LBLUE} "create 'remote' group" ${NC}
groupadd remote

#setup the remote access banner
echo -e ${LBLUE} "Setup banner /etc/issue.net" ${NC}
cat <<EOF > /etc/issue.net

WARNING:  Unauthorized access to this system is forbidden and will be
prosecuted by law. By accessing this system, you agree that your actions
may be monitored if unauthorized usage is suspected.

EOF

# Setup banner /etc/issue.net permissions
echo -e ${LBLUE} "Setup banner /etc/issue.net permissions" ${NC}
chown root:root /etc/issue.net
chmod 644 /etc/issue.net

#setup the console access banner
echo -e ${LBLUE} "Setup banner /etc/issue" ${NC}
cat <<EOF > /etc/issue

WARNING:  Unauthorized access to this system is forbidden and will be
prosecuted by law. By accessing this system, you agree that your actions
may be monitored if unauthorized usage is suspected.

EOF

# Setup banner /etc/issue permissions
echo -e ${LBLUE} "Setup banner /etc/issue permissions" ${NC}
chown root:root /etc/issue
chmod 644 /etc/issue

#setup motd
echo -e ${LBLUE} "Setup banner /etc/motd" ${NC}
cp /etc/motd /etc/motd.bkp
cat ssh/motd/joker > /etc/motd
chown root:root /etc/motd
chmod 644 /etc/motd

# Check /etc/ssh/sshd_config syntax
echo -e ${LBLUE} "Check /etc/ssh/sshd_config syntax" ${NC}
sshd -T || echo -e "/etc/ssh/sshd_config has bad syntax\nexiting...\n"

# Remove Short Diffie-Hellman Keys
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
echo -e ${LBLUE} "Remove Short Diffie-Hellman Keys" ${NC}
cp --preserve /etc/ssh/moduli /etc/ssh/moduli.$TIMESTAMP
awk '$5 >= 3071 {print $0}' /etc/ssh/moduli.$TIMESTAMP > /etc/ssh/moduli

# Restart ssh service
echo -e ${LBLUE} "Restart ssh service" ${NC}
systemctl restart sshd

# Fail2ban IDS install
echo -e ${LBLUE} "Fail2ban IDS install" ${NC}
apt-get install fail2ban -y

# Fail2ban service restart
echo -e ${LBLUE} "Fail2ban service restart" ${NC}
systemctl restart fail2ban || systemctl start fail2ban

echo
echo "TO-DO:"
echo "[ ] Add users to 'wheel' group"
echo "[ ] Add users to 'remote' group"
echo "[ ] Set the SSH Keys"
echo "[ ] Disable password login for all users"
echo "[ ] Disable Remote Root login"
echo "[ ] Set Google 2FA"
echo

echo -e ${GREEN} "Finish Hardening!" ${NC}
