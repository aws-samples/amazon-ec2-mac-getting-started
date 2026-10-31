# EC2 Mac observability

These files install the [Amazon CloudWatch agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html) on EC2 Mac instances with a configuration suited to Apple developer workloads. They also install **ec2-mac-health**, a small script that reports macOS health information the agent doesn't collect by itself.

For a step-by-step guide, including which metrics to watch and which alarms to create, see [Set up observability](../../steps/05_observability.md).

| File | What it does |
|---|---|
| [`install-cloudwatch-agent.sh`](install-cloudwatch-agent.sh) | Downloads the agent from the Amazon S3 bucket in your Region, checks that the package is signed by Amazon, installs it along with ec2-mac-health, and starts the agent with your configuration. Use it as EC2 user data, in Systems Manager, in a Jamf policy, or in Terminal. It's safe to run more than once. |
| [`cloudwatch-agent-config.json`](cloudwatch-agent-config.json) | The agent configuration: 5 system metrics, a StatsD listener on the local address for ec2-mac-health, and 3 log files |
| [`ssm-document.json`](ssm-document.json) | A Systems Manager Command document that runs the install script, for Run Command and State Manager |

## Before you begin

### 1. Attach an IAM instance profile

Give the instance a role with these AWS managed policies:
- `CloudWatchAgentServerPolicy`, so the agent can send metrics and logs and read its configuration from Parameter Store.
- `AmazonSSMManagedInstanceCore`, if you plan to use Systems Manager.

### 2. Save the agent configuration

Save `cloudwatch-agent-config.json` as a Parameter Store parameter. The name must start with `AmazonCloudWatch-`, because `CloudWatchAgentServerPolicy` only allows the agent to read parameters with that prefix:

```
aws ssm put-parameter --name AmazonCloudWatch-ec2-mac --type String --value file://cloudwatch-agent-config.json
```

If you'd rather keep the file on the instance (for example, deployed with Jamf), copy it there and use `file:/path/to/cloudwatch-agent-config.json` as the configuration source.

### 3. Check network access

The instance needs to reach CloudWatch, CloudWatch Logs, Systems Manager (for Parameter Store), and Amazon S3 (to download the agent). If it runs in a subnet without internet access, create these VPC endpoints:
- Interface endpoints for `monitoring`, `logs`, `ssm`, `ssmmessages`, and `ec2messages`
- A gateway endpoint for `s3`

Give the interface endpoints a security group that allows inbound TCP 443 from your instances' security group.

## Install

Every method runs the same script. By default, it reads the configuration from `ssm:AmazonCloudWatch-ec2-mac`.

### EC2 user data

When you launch the instance, paste the contents of `install-cloudwatch-agent.sh` into the user data field. The script runs the first time the instance starts.

### Systems Manager (Run Command or State Manager)

```
aws ssm create-document --name EC2Mac-Observability-Install --document-type Command \
  --document-format JSON --content file://ssm-document.json

# Install on every instance tagged Observability=cloudwatch-agent, including ones you launch later:
aws ssm create-association --association-name EC2Mac-Observability \
  --name EC2Mac-Observability-Install \
  --targets Key=tag:Observability,Values=cloudwatch-agent \
  --schedule-expression "rate(1 day)"
```

Tag your instances before you create the association, so that the first run includes them.

### Jamf

Add `install-cloudwatch-agent.sh` to Jamf Pro as a script, and run it from a policy. Set **Parameter 4** to the configuration source, such as `ssm:AmazonCloudWatch-ec2-mac` or `file:/usr/local/etc/ec2-mac/cloudwatch-agent-config.json`. The script ignores Jamf's parameters 1 through 3.

### Terminal

```
sudo CONFIG_SOURCE=ssm:AmazonCloudWatch-ec2-mac /bin/bash install-cloudwatch-agent.sh
```

To update the agent to the latest version later, run the script again with `UPGRADE_AGENT=1`.

## Check the installation

```
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
sudo launchctl print system/com.aws-samples.ec2-mac-health | grep -E "runs|last exit"
"/Library/Application Support/ec2-mac-health/ec2-mac-health.sh" --print
```

The script writes its log to `/var/log/amazon/ec2/cloudwatch-agent-install.log`. After a few minutes, the metrics show up in CloudWatch under the `CWAgent` namespace, tagged with the instance ID.

## Uninstall

The **Uninstall** action of `AWS-ConfigureAWSPackage` won't remove an agent that this script installed, because it only removes packages that Systems Manager Distributor installed. Remove the agent and ec2-mac-health with these commands instead:

```
sudo launchctl bootout system/com.aws-samples.ec2-mac-health
sudo rm -f /Library/LaunchDaemons/com.aws-samples.ec2-mac-health.plist
sudo rm -rf "/Library/Application Support/ec2-mac-health"
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop
sudo rm -rf /Library/LaunchDaemons/com.amazon.cloudwatch.agent.plist /opt/aws/amazon-cloudwatch-agent
sudo pkgutil --forget com.amazon.cloudwatch.agent
```
