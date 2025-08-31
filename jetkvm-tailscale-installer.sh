#!/usr/bin/env zsh
set -euo pipefail

############################
# JetKVM + Tailscale Setup #
############################

# 1. Gather inputs
echo "=============================================================================="
echo "JetKVM Tailscale Setup"
echo ""
echo "Prerequisite:"
echo "  • Developer Mode enabled in JetKVM UI"
echo "  • Your SSH public key installed."
echo ""
read -rp "JetKVM IP address (e.g. 10.10.0.6): " JETKVM_IP
read -rp "Any extra SSH options? (e.g. -i ~/.ssh/mykey) " SSH_OPTS
read -rp "Custom Tailscale device name: " TS_DEVICE_NAME

SSH="ssh ${SSH_OPTS:-} root@${JETKVM_IP}"
TS_BASE_URL="https://pkgs.tailscale.com/stable/tailscale_latest_arm.tgz"

echo ""
echo "=============================================================================="
echo "Installing"
echo "Downloading Tailscale and uploading to JetKVM..."
curl -fsSL "${TS_BASE_URL}" \
  | gzip -d \
  | ${SSH} "cat > /userdata/tailscale.tar"
echo "✔ Uploaded /userdata/tailscale.tar"

# 2. SSH in and install
echo "→ Installing on JetKVM..."
${SSH} <<EOF
  set -euo pipefail
  modprobe tun || true

  cd /userdata
  rm -rf tailscale-state tailscale
  tar xf tailscale.tar
  rm tailscale.tar
  mv tailscale_*_arm tailscale
  chmod +x tailscale/tailscale tailscale/tailscaled

  echo "Tailscale version on device:"
  ./tailscale/tailscale --version

  # Create init script
  cat >/etc/init.d/S22tailscale << 'INIT'
#!/bin/sh
# /etc/init.d/S22tailscale — start/stop Tailscale on JetKVM

case "\$1" in
  start)
    modprobe tun || true
    /userdata/tailscale/tailscaled -statedir /userdata/tailscale-state &
    ;;
  stop)
    killall tailscaled || true
    ;;
  *)
    echo "Usage: \$0 {start|stop}"
    exit 1
    ;;
esac
INIT

  chmod +x /etc/init.d/S22tailscale

  # Restart the service so the init‐script is in place
  /etc/init.d/S22tailscale stop || true
  /etc/init.d/S22tailscale start

  echo ""
  echo "Now you need to authenticate via Tailscale:"
  /userdata/tailscale/tailscale login

  echo "Bringing up the Tailscale interface..."
  /userdata/tailscale/tailscale up --hostname "${TS_DEVICE_NAME}" --advertise-exit-node

  echo ""
  echo "Init script installed and Tailscale is now running!"
EOF

echo "=============================================================================="
echo "To uninstall Tailscale from your JetKVM, run:"
echo "  ${SSH} \"rm -rf /userdata/tailscale /userdata/tailscale-state /etc/init.d/S22tailscale && reboot\""
echo "=============================================================================="
echo "Since JetKVM does not support kernel-level NAT (iptables/nftables), exit node does not support traffic forwarding."
echo "→ When using JetKVM as a exit node, you have only access to the JetKVM web interface, but no internet/network access!"
echo "=============================================================================="
echo ""
echo "Happy tunneling! 🎉"
echo ""
