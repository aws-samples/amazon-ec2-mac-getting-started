## **Set up observability for your EC2 Mac instance**

### **Before you begin:**

* Ensure that you have launched an EC2 Mac instance as described [here](02_launch_instance.md).

* Ensure that you can run commands on the instance, either with [AWS Systems Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/what-is-systems-manager.html) or over SSH as described [here](03_connect_and_enable.md).

* Download the scripts and the configuration file from [apps-and-scripts/observability](../apps-and-scripts/observability/).

---
### **Overview**
---

Every EC2 Mac instance sends standard `AWS/EC2` metrics to Amazon CloudWatch, such as status checks, network traffic, and Amazon EBS activity. To also track memory, disk space, processes, and macOS health, and to collect logs, you need the [Amazon CloudWatch agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html).

You install the CloudWatch agent and **ec2-mac-health**, a script that reports macOS health data the agent doesn't collect. It sends values to the agent over StatsD on `127.0.0.1:8125`, which only the instance can reach.

With the included configuration, the agent sends these metrics to the `CWAgent` namespace, tagged with the instance ID:

| Metric | Source | Description |
|---|---|---|
| `disk_free` | CloudWatch agent | Free space on `/System/Volumes/Data`, where DerivedData, Simulator runtimes, and build output are stored |
| `swap_used` | CloudWatch agent | Swap space in use. If it keeps growing, the workload needs more memory than the instance has. |
| `mem_available_percent` | CloudWatch agent | Percentage of memory available to apps |
| `cpu_usage_active` | CloudWatch agent | Total CPU usage, reported every minute |
| `processes_total` | CloudWatch agent | Number of running processes |
| `memory_pressure_level` | ec2-mac-health | Memory pressure as macOS reports it: `1` normal, `2` warning, `4` critical |
| `thermal_pressure_level` | ec2-mac-health | Thermal pressure as macOS reports it, from `0` (nominal) to `4` (sleeping) |
| `thermal_throttling` | ec2-mac-health | `1` when the chip is slowing down because of heat, otherwise `0` |
| `panic_reports` | ec2-mac-health | Number of kernel panic reports from the last 7 days |
| `uptime_seconds` | ec2-mac-health | Seconds since the instance last started |

It also sends these logs to CloudWatch Logs, kept for 30 days:

* `/var/log/amazon/ec2/system-monitoring.log`
* `/var/log/amazon/ec2/ec2-macos-init.log`, including user data output
* `/var/log/amazon/ec2/cloudwatch-agent-install.log`

---
### **Step 1: Attach an IAM instance profile**
---

Attach an [IAM instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html) to the instance with these AWS managed policies:

* `CloudWatchAgentServerPolicy`, so the agent can send metrics and logs and read its configuration from Parameter Store.
* `AmazonSSMManagedInstanceCore`, if you plan to use Systems Manager to install the agent.

---
### **Step 2: Store the agent configuration**
---

Save [`cloudwatch-agent-config.json`](../apps-and-scripts/observability/cloudwatch-agent-config.json) as a Parameter Store parameter. The name must start with `AmazonCloudWatch-`, because `CloudWatchAgentServerPolicy` only allows the agent to read parameters with that prefix.

```
aws ssm put-parameter --name AmazonCloudWatch-ec2-mac --type String \
  --value file://cloudwatch-agent-config.json --region <region>
```

If you'd rather keep the file on the instance, copy it there and use `file:<path>` as the configuration source in Step 3.

---
### **Step 3: Install the CloudWatch agent**
---

The [`install-cloudwatch-agent.sh`](../apps-and-scripts/observability/install-cloudwatch-agent.sh) script:

1. Downloads the agent from the Amazon S3 bucket in your Region.
2. Checks that the package is signed by Amazon.
3. Installs the agent and ec2-mac-health.
4. Loads the configuration and starts the agent.

Run it as root. It's safe to run more than once. By default, it reads the configuration from `ssm:AmazonCloudWatch-ec2-mac`.

Use any of these methods:

#### **EC2 user data**

When you launch the instance, paste the contents of `install-cloudwatch-agent.sh` into the [user data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) field. The script runs the first time the instance starts.

#### **AWS Systems Manager State Manager**

Create a Command document from [`ssm-document.json`](../apps-and-scripts/observability/ssm-document.json), and then create an association that targets your EC2 Mac instances by tag. Systems Manager installs the agent on every instance with that tag, including ones you launch later.

```
aws ssm create-document --name EC2Mac-Observability-Install \
  --document-type Command --document-format JSON --content file://ssm-document.json

aws ssm create-association --association-name EC2Mac-Observability \
  --name EC2Mac-Observability-Install \
  --targets Key=tag:Observability,Values=cloudwatch-agent \
  --schedule-expression "rate(1 day)"
```

Tag your instances before you create the association, so that the first run includes them.

#### **AWS Systems Manager Run Command**

Run the `EC2Mac-Observability-Install` document on the instances you choose, or paste the script into the `AWS-RunShellScript` document.

#### **Jamf**

Add `install-cloudwatch-agent.sh` to Jamf Pro as a script, and run it from a policy. Set **Parameter 4** to the configuration source, such as `ssm:AmazonCloudWatch-ec2-mac`.

#### **Terminal**

```
sudo CONFIG_SOURCE=ssm:AmazonCloudWatch-ec2-mac /bin/bash install-cloudwatch-agent.sh
```

To update the agent to the latest version later, run the script again with `UPGRADE_AGENT=1`.

---
### **Step 4: Verify the installation**
---

On the instance, check that the agent is running and that ec2-mac-health returns values:

```
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
"/Library/Application Support/ec2-mac-health/ec2-mac-health.sh" --print
```

Wait a few minutes, then open the [CloudWatch console](https://console.aws.amazon.com/cloudwatch/home#metricsV2), choose **All metrics**, and choose **CWAgent** to find your instance's metrics.

---
### **Step 5: Create alarms**
---

These alarms are a good starting point for build and test machines. Adjust the thresholds to fit your workload and disk size. Use a 1-minute period unless the table says otherwise.

| Alarm | Metric | Statistic | Condition | Datapoints to alarm | Missing data |
|---|---|---|---|---|---|
| Disk almost full | `disk_free` | Minimum | Less than 20 to 25% of the volume size | 1 of 1 | Breaching |
| Memory exhaustion | `swap_used` | Maximum | Greater than 2 GB (5-minute period) | 2 of 3 | Not breaching |
| Memory pressure | `memory_pressure_level` | Maximum | Greater than or equal to 2 | 5 of 10 | Not breaching |
| Thermal throttling | `thermal_throttling` | Maximum | Greater than or equal to 1 | 2 of 2 | Not breaching |
| Kernel panic | `panic_reports` | Maximum | Greater than 0 | 1 of 1 | Not breaching |
| Reboot | `uptime_seconds` | Minimum | Less than 600 | 1 of 1 | Not breaching |
| Sustained CPU | `cpu_usage_active` | Average | Greater than 95 | 30 of 30 | Not breaching |
| EBS throughput limit | `VolumeThroughputExceededCheck` (`AWS/EBS`) | Maximum | Greater than or equal to 1 | 10 of 15 | Not breaching |
| EBS stalled I/O | `VolumeStalledIOCheck` (`AWS/EBS`) | Maximum | Greater than or equal to 1 | 10 of 10 | Not breaching |
| Agent not reporting | `disk_free` | SampleCount | Less than 1 | 3 of 3 | Breaching |
| Instance health | `StatusCheckFailed` (`AWS/EC2`) | Maximum | Greater than or equal to 1 (5-minute period) | 2 of 2 | Missing |

* Builds often reach 100% CPU. The sustained CPU alarm catches usage that never drops, such as a stuck Simulator or test run.
* For the `AWS/EBS` metrics, include both the `VolumeId` and `InstanceId` dimensions in the alarm.
* *Agent not reporting* fires several minutes after the agent stops, because CloudWatch evaluates extra periods when data is missing.
* To get notified about scheduled maintenance and host retirement, [monitor AWS Health events](https://docs.aws.amazon.com/health/latest/ug/cloudwatch-events-health.html).

---
### **Tips for customizing the configuration**
---

* For disk alarms, use `disk_free` on `/System/Volumes/Data`. The `/` volume is a read-only copy of the system that shares its free space with the data volume, so `disk_used_percent` on either one doesn't show how full the disk really is.
* For memory alarms, use `memory_pressure_level` and `swap_used` instead of `mem_available_percent`. macOS uses spare memory for caching and compression, so available memory can look healthy even when the Mac is short on memory.
* Leave out the Linux-only measurements `processes_dead`, `processes_paging`, `processes_total_threads`, and `processes_wait`. On macOS, the agent won't start if the configuration includes any of them.
* `cpu_usage_iowait` always reads zero on macOS. To spot storage bottlenecks, use the `AWS/EBS` metrics instead.
* Don't use `"resources": ["*"]` for `diskio` and `net`. macOS has many virtual network interfaces and disks, and each one becomes a separate (billed) custom metric. List only the devices you care about.

---
### **Security**
---

* The agent runs as root and sends any file in its configuration to CloudWatch Logs. Allow only administrators to change the `AmazonCloudWatch-*` parameters or the `file:` configuration.
* `ec2-macos-init.log` includes the output of your user data. Don't put passwords, keys, or other secrets in user data.
* Limit who can read the `/ec2-mac/*` log groups. To encrypt them with your own key, see [Encrypt log data in CloudWatch Logs using AWS KMS](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html).

---
### **Instances in private subnets**
---

If your instances run in a subnet without internet access, create these [VPC endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html):

* Interface endpoints for `monitoring`, `logs`, `ssm`, `ssmmessages`, and `ec2messages`, with private DNS turned on. Give them a security group that allows inbound TCP 443 from your EC2 Mac instances' security group.
* A gateway endpoint for `s3`, so the script can download the agent.

---
### **Uninstall**
---

To remove the agent and ec2-mac-health, follow the steps in the [observability README](../apps-and-scripts/observability/README.md#uninstall). The **Uninstall** action of `AWS-ConfigureAWSPackage` won't remove an agent that this script installed, because it only removes packages that Systems Manager Distributor installed.
