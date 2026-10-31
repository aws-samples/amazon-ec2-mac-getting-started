#!/bin/bash

### EC2 Mac observability
### Installs the Amazon CloudWatch agent and ec2-mac-health, a small script that sends macOS health
### information (memory pressure, thermal pressure, panic reports, and uptime) to the agent over a
### local StatsD listener. Then it starts the agent with your configuration.
###
### Run it as root. The same script works as EC2 user data, in Systems Manager Run Command or
### State Manager, in a Jamf policy, or in Terminal with sudo. It's safe to run more than once.
###
### Where to read the agent configuration from (same format as the agent's -c option):
###   ssm:<Parameter Store name>   The name must start with AmazonCloudWatch-, because
###                                CloudWatchAgentServerPolicy only allows reading that prefix.
###   file:<path>                  A JSON file on the instance, for example one deployed by Jamf.
### Set it with Jamf parameter 4, with the CONFIG_SOURCE environment variable, or by changing
### the default below.
###
### Set UPGRADE_AGENT=1 to replace an installed agent with the latest version.

CONFIG_SOURCE="${4:-${CONFIG_SOURCE:-ssm:AmazonCloudWatch-ec2-mac}}"
UPGRADE_AGENT="${UPGRADE_AGENT:-0}"

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
CTL=/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl
HELPER_DIR="/Library/Application Support/ec2-mac-health"
HELPER="${HELPER_DIR}/ec2-mac-health.sh"
HELPER_LABEL=com.aws-samples.ec2-mac-health
HELPER_PLIST=/Library/LaunchDaemons/${HELPER_LABEL}.plist
LOG=/var/log/amazon/ec2/cloudwatch-agent-install.log

set -euo pipefail
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1
echo "$(date -u +%FT%TZ) install start (config: $CONFIG_SOURCE)"

if [ "$(id -u)" -ne 0 ]; then
  echo "must run as root"
  exit 1
fi

### Look up the Region (from instance metadata) and the CPU architecture.
TOKEN=$(curl -sf -X PUT http://169.254.169.254/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
REGION=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
case "$(uname -m)" in
  arm64) ARCH=arm64 ;;
  x86_64) ARCH=amd64 ;;
  *) echo "unsupported architecture $(uname -m)"; exit 1 ;;
esac

### Download the agent from the S3 bucket in this Region, check that it's signed by Amazon, and install it.
if [ ! -x "$CTL" ] || [ "$UPGRADE_AGENT" = "1" ]; then
  if [ -x "$CTL" ]; then
    echo "stopping the existing agent before upgrading"
    "$CTL" -a stop || true
    launchctl bootout system/com.amazon.cloudwatch.agent 2>/dev/null || true
  fi
  TMP=$(mktemp -d)
  URL="https://amazoncloudwatch-agent-${REGION}.s3.${REGION}.amazonaws.com/darwin/${ARCH}/latest/amazon-cloudwatch-agent.pkg"
  echo "downloading $URL"
  curl -sf --retry 5 -o "$TMP/amazon-cloudwatch-agent.pkg" "$URL"
  SIGNATURE=$(pkgutil --check-signature "$TMP/amazon-cloudwatch-agent.pkg" || true)
  case "$SIGNATURE" in
    *"Developer ID Installer: AMZN Mobile LLC (94KV3E626L)"*) ;;
    *) echo "package signature check failed"; exit 1 ;;
  esac
  installer -pkg "$TMP/amazon-cloudwatch-agent.pkg" -target /
  rm -rf "$TMP"
else
  echo "CloudWatch agent already installed, skipping install (set UPGRADE_AGENT=1 to upgrade)"
fi

### Install ec2-mac-health. The script writes it directly instead of downloading it, so this also works
### in subnets without internet access. launchd runs it as root, so keep it in a folder only root can change.
mkdir -p "$HELPER_DIR"
chown root:wheel "$HELPER_DIR"
chmod 755 "$HELPER_DIR"
rm -f "$HELPER"
cat > "$HELPER" <<'HELPER_EOF'
#!/bin/bash

### ec2-mac-health: sends macOS health values to the CloudWatch agent's StatsD listener on 127.0.0.1.
### The agent publishes them as custom metrics, tagged with the instance ID.
###   memory_pressure_level   memory pressure as macOS reports it: 1 normal, 2 warning, 4 critical
###   thermal_pressure_level  0 nominal, 1 moderate, 2 heavy, 3 trapping, 4 sleeping
###   thermal_throttling      1 when thermal pressure is heavy or higher, otherwise 0
###   panic_reports           number of kernel panic reports from the last 7 days
###   uptime_seconds          seconds since the instance started; a drop means it restarted
### Run it with --print to show the values without sending them.

PATH=/usr/bin:/bin:/usr/sbin:/sbin
STATSD_HOST=127.0.0.1
STATSD_PORT=8125

lines=""
add() { [ -n "$2" ] && lines="${lines}$1:$2|g"$'\n'; }

add memory_pressure_level "$(sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null)"

thermal=$(notifyutil -g com.apple.system.thermalpressurelevel 2>/dev/null | awk '{print $2}')
if [ -n "$thermal" ]; then
  add thermal_pressure_level "$thermal"
  if [ "$thermal" -ge 2 ]; then add thermal_throttling 1; else add thermal_throttling 0; fi
fi

if [ -r /Library/Logs/DiagnosticReports ]; then
  add panic_reports "$(find /Library/Logs/DiagnosticReports -maxdepth 1 -name '*.panic' -Btime -7 2>/dev/null | wc -l | tr -d ' ')"
fi

boot=$(sysctl -n kern.boottime 2>/dev/null | sed -E 's/^\{ sec = ([0-9]+),.*/\1/')
[ -n "$boot" ] && add uptime_seconds "$(( $(date +%s) - boot ))"

if [ "${1:-}" = "--print" ]; then
  printf '%s' "$lines"
else
  printf '%s' "$lines" | nc -u -w 1 "$STATSD_HOST" "$STATSD_PORT"
fi
exit 0
HELPER_EOF
chmod 755 "$HELPER"
chown root:wheel "$HELPER"

cat > "$HELPER_PLIST" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${HELPER_LABEL}</string>
	<key>ProgramArguments</key>
	<array>
		<string>${HELPER}</string>
	</array>
	<key>StartInterval</key>
	<integer>60</integer>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
PLIST_EOF
chmod 644 "$HELPER_PLIST"
chown root:wheel "$HELPER_PLIST"
launchctl bootout "system/${HELPER_LABEL}" 2>/dev/null || true
launchctl bootstrap system "$HELPER_PLIST"

### Load the configuration and start the agent.
"$CTL" -a fetch-config -m ec2 -s -c "$CONFIG_SOURCE"
### The agent can take a few seconds to report that it's running.
for attempt in 1 2 3 4 5 6; do
  ### Save the output first. With pipefail, piping into grep -q can fail even when the text matches.
  AGENT_STATUS=$("$CTL" -a status 2>/dev/null || true)
  case "$AGENT_STATUS" in *'"status": "running"'*) break ;; esac
  if [ "$attempt" -eq 6 ]; then
    echo "CloudWatch agent is not running"
    exit 1
  fi
  sleep 5
done

echo "helper values:"
"$HELPER" --print
echo "$(date -u +%FT%TZ) install done"
exit 0;
