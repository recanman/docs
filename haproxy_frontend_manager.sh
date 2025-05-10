#!/bin/bash
# made by recanman
set -eo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

CLUSTER_FILE="/etc/haproxy/cluster_nodes"
SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

ensure_deps() {
    echo "Checking required dependencies..."
    local packages=("haproxy" "openssh-client" "openssh-server" "sshpass" "rsync" "cron")
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -qw "$pkg"; then
            echo "$pkg is not installed. Installing..."
            apt-get install -y "$pkg" || { echo "Failed to install $pkg"; exit 1; }
        else
            echo "$pkg is already installed."
        fi
    done
}

ensure_ssh_keys() {
    echo "Ensuring SSH keys are set up..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    if [ ! -f "$SSH_DIR/id_rsa" ]; then
        echo "Generating SSH keys..."
        ssh-keygen -t rsa -N "" -f "$SSH_DIR/id_rsa"
    fi
    touch "$AUTHORIZED_KEYS"
    chmod 600 "$AUTHORIZED_KEYS"
}

distribute_cluster_file() {
    echo "Distributing the cluster file to other nodes..."
    if [ ! -f "$CLUSTER_FILE" ]; then
        echo "Cluster file $CLUSTER_FILE not found."
        exit 1
    fi

    local my_ip
    my_ip=$(ip route get 1 | awk '{print $7; exit}')

    while IFS='|' read -r role ip priority; do
        if [[ "$ip" == "$my_ip" ]]; then
            continue
        fi

        echo "Copying cluster file to $ip..."
        ssh-keyscan -H "$ip" >> "$SSH_DIR/known_hosts"
        scp "$CLUSTER_FILE" "root@$ip:$CLUSTER_FILE" || {
            echo "Failed to copy cluster file to $ip. Continuing..."
            continue
        }
    done < <(grep -v '^#' "$CLUSTER_FILE")
}

check_leader_status() {
    local leader_ip
    leader_ip=$(awk -F'|' '/^leader/ {print $2}' "$CLUSTER_FILE")

    if ! ping -c1 -W1 "$leader_ip" >/dev/null; then
        echo "Leader unreachable. Using failover..."
        leader_ip=$(get_failover)
    fi

    echo "$leader_ip"
}

get_failover() {
    local failover_ip
    failover_ip=$(awk -F'|' '/^failover/ {print $2 "|" $3}' "$CLUSTER_FILE" | sort -t'|' -k2n | head -n1 | cut -d'|' -f1)
    if [ -z "$failover_ip" ]; then
        echo "No failover node available."
        exit 1
    fi
    echo "$failover_ip"
}

replicate_certificates() {
    local my_ip leader_ip
    my_ip=$(ip route get 1 | awk '{print $7; exit}')
    leader_ip=$(awk -F'|' '/^leader/ {print $2}' "$CLUSTER_FILE")
	if ! ping -c1 -W1 "$leader_ip" >/dev/null; then
		echo "Leader unreachable. Using failover..."
		leader_ip=$(get_failover)
	fi

    if [ "$my_ip" == "$leader_ip" ]; then
        echo "This is the leader node. No need to replicate certificates."
        return
    fi

    echo "Replicating certificates from leader ($leader_ip)..."
    mkdir -p /etc/letsencrypt
    rsync -avz "$leader_ip:/etc/letsencrypt/" /etc/letsencrypt/
    systemctl reload haproxy
}

distribute_ssh_keys() {
    local ssh_pass="$1"
    echo "Distributing SSH keys to other nodes..."

    while IFS='|' read -r role ip priority; do
        if [[ "$ip" == "$(ip route get 1 | awk '{print $7; exit}')" ]]; then
            continue
        fi

        echo "Copying SSH key to $ip..."
        ssh-keyscan -H "$ip" >> "$SSH_DIR/known_hosts"
        sshpass -p "$ssh_pass" ssh-copy-id "root@$ip"
    done < <(grep -v '^#' "$CLUSTER_FILE")
}

bootstrap() {
    echo "Bootstrapping this node..."
	if [ -f "$CLUSTER_FILE" ]; then
		echo "Cluster file already exists. Do you want to overwrite it? (y/n)"
		read -r overwrite
		if [[ "$overwrite" != "y" ]]; then
			echo "Exiting without changes."
			exit 0
		fi
	fi

	echo "Do you want this node to be the leader? (y/n)"
	read -r is_leader
	if [[ "$is_leader" != "y" ]]; then
		echo "This node will be a non-leader."
		echo "Enter the IP address of the leader node:"
		read -r leader_ip
	fi

    apt update
    ensure_deps
    ensure_ssh_keys

    echo "Moving script to /usr/local/bin/manage_cluster..."
    cp "$0" /usr/local/bin/manage_cluster

    echo "Adding cron job for certificate replication..."

	# Create crontab if not already exists
	local cron_job="0 0 * * * /usr/local/bin/manage_cluster replicate_certificates"
	local already_exists=$(crontab -l | grep -F "$cron_job")
	if [ -z "$already_exists" ]; then
		(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	else
		echo "Cron job already exists: $cron_job"
	fi

	if [[ "$is_leader" == "y" ]]; then
		local my_ip
		my_ip=$(ip route get 1 | awk '{print $7; exit}')
		echo "leader|$my_ip" >> "$CLUSTER_FILE"
	else
		# Copy ssh key to the leader node
		echo "Enter the SSH username for the leader node ($leader_ip):"
		read -r ssh_user
		echo "Enter the SSH password for the user $ssh_user@$leader_ip:"
		read -rs ssh_pass
		echo "Copying SSH key to $leader_ip..."
		ssh-keyscan -H "$leader_ip" >> "$SSH_DIR/known_hosts"
		sshpass -p "$ssh_pass" ssh-copy-id "$ssh_user@$leader_ip"
	fi

    echo "Cluster bootstrapped with node $my_ip."
}

addserver() {
    local new_ip="$1"
    if [ -z "$new_ip" ]; then
        echo "Usage: $0 addserver <server-ip>"
        exit 1
    fi

	echo "You need to have run bootstrap on the new node before adding it. Have you done that? (y/n)"
	read -r bootstrap_done
	if [[ "$bootstrap_done" != "y" ]]; then
		echo "Please run bootstrap on the new node first."
		exit 1
	fi

    echo "Enter the SSH username for the new node ($new_ip):"
    read -r ssh_user

    echo "Enter the SSH password for the user $ssh_user@$new_ip:"
    read -rs ssh_pass
    echo

    ensure_ssh_keys

    echo "Copying SSH key to $new_ip..."
    ssh-keyscan -H "$new_ip" >> "$SSH_DIR/known_hosts"
    sshpass -p "$ssh_pass" ssh-copy-id "$ssh_user@$new_ip"

    echo "Choose role for this node:"
    echo "1) Regular node"
    echo "2) Failover node"
    read -rp "Selection [1-2]: " role_choice

    local role line
    case "$role_choice" in
        1)
            role="node"
            line="$role|$new_ip"
            ;;
        2)
            role="failover"
            echo -n "Enter failover priority (lower = higher priority), or leave blank for default: "
            read -r priority
            [ -z "$priority" ] && priority=100
            line="$role|$new_ip|$priority"
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    if grep -q "|$new_ip" "$CLUSTER_FILE"; then
        echo "Node $new_ip already exists in the cluster file."
    else
        echo "$line" >> "$CLUSTER_FILE"
        sort -t '|' -k2,2 -u "$CLUSTER_FILE" -o "$CLUSTER_FILE"
        distribute_cluster_file
        distribute_ssh_keys "$ssh_pass"
        echo "Server $new_ip added."
    fi
}

removeserver() {
    local rem_ip="$1"
    if [ -z "$rem_ip" ]; then
        echo "Usage: $0 removeserver <server-ip>"
        exit 1
    fi

    if grep -q "|$rem_ip" "$CLUSTER_FILE"; then
        sed -i "/|$rem_ip/d" "$CLUSTER_FILE"
        distribute_cluster_file
        echo "Server $rem_ip removed from the cluster."
    else
        echo "Server $rem_ip not found in the cluster."
    fi
}

case "$1" in
    bootstrap)
        bootstrap
        ;;
    addserver)
        addserver "$2"
        ;;
    removeserver)
        removeserver "$2"
        ;;
	distribute_cluster_file)
		distribute_cluster_file
		;;
    replicate_certificates)
        replicate_certificates
        ;;
    *)
        echo "Usage: $0 {bootstrap|addserver <ip>|removeserver <ip>|replicate_certificates|distribute_cluster_file}"
        exit 1
        ;;
esac
