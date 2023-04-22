
ip="$1"
hostname="$2"
echo "set ip to $ip, hostname to $hostname"


# from chatGPT

    # Check if IP address is valid
    if [[ ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid IP address: $ip"
        return 1
    fi

    # Check if hostname is valid
    if [[ ! $hostname =~ ^[a-zA-Z0-9\-]+$ ]]; then
        echo "Invalid hostname: $hostname"
        return 1
    fi

echo "set ip to $1, hostname to $2, and add DNS"

# Get the name of the current network interface
iface=$(ip link | awk '/state UP/{print $2}' | sed 's/://')

# Get the current configuration file for the network interface
cfg_file=$(ls /etc/sysconfig/network-scripts/ifcfg-$iface 2>/dev/null)

# If the configuration file exists, modify it
if [[ -n "$cfg_file" ]]; then
  echo "Modifying $cfg_file"

  # Replace the current IP address with a new one (e.g., 192.168.1.100)
  sed -i "s/^IPADDR=.*/IPADDR=$1/" "$cfg_file"

  # Add a new DNS server (e.g., 8.8.8.8)
  #echo "DNS1=8.8.8.8" >> "$cfg_file"

  # Update BOOTPROTO to static
  sed -i 's/^BOOTPROTO=.*/BOOTPROTO=static/' "$cfg_file"

  # Change the hostname to a specific value (e.g., myhost)
  hostnamectl set-hostname "$2"

  # Restart the network service to apply the changes
  systemctl restart NetworkManager
else
  echo "Configuration file for $iface not found"
fi

