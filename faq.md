## **Frequently Asked Questions about Amazon EC2 Mac Instances**

1.	[How do you release a dedicated host?](#release)
1.	[How many Mac instances can be supported on a Mac dedicated host?](#one-to-one)
1.	[Can you share Mac dedicated hosts with other AWS accounts in your organization?](#ram)
1.	[What macOS AMIs are available?](#amis)
1.	[How do you pass user data or automated configurations to an EC2 Mac instance?](#userdata)
1.	[How do you connect to EC2 Mac instances?](#connect)
1.	[How do you connect via remote screen sharing to an EC2 Mac instance?](#remote)
1.	[How do you install Xcode on an EC2 Mac instance?](#xcode)
1.	[Is there Wi-Fi and Bluetooth access on Mac instances?](#wifi)
1.	[Is there access to the microphone input or audio output on an EC2 Mac instance?](#audio)
1.	[Can you update the EFI NVRAM variables on an EC2 Mac instance?](#nvram)
1.	[Can you use FileVault to encrypt the EBS boot volume on EC2 Mac instances?](#filevault)
1.	[What is the release cadence of macOS AMIs?](#cadence)
1.	[Can you run macOS AMIs anywhere other than EC2 Mac instances?](#amis-elsewhere)
1.	[Can you bring your own macOS image to run on EC2 Mac instances?](#byo)
1.	[What agents and packages are included in EC2 macOS AMIs?](#packages)
1.	[Can you update the agents and packages included in macOS AMIs?](#update-packages)
1.	[Can you apply OS and software updates to your Mac instances directly from Apple Update Servers?](#update-os)
1.	[Do EC2 Mac instances support the Nitro system?](#nitro)
1.	[How many EBS volumes and ENIs are supported by EC2 Mac instances?](#ebs-and-eni)
1.	[Do EC2 Mac instances support EBS?](#ebs)
1.	[Do EC2 Mac instances support on-demand and spot hibernation?](#hibernation)
1.	[Do EC2 Mac instances support booting from instance storage?](#instance-storage)
1.	[Do EC2 Mac instances support Auto Recovery or Host Recovery?](#recovery)
1.	[Do EC2 Mac instances support Placement Groups?](#groups)
1.	[Do EC2 Mac instances support FSx?](#fsx)
1.	[Do EC2 Mac instances support EFS?](#efs)
1.	[Do EC2 Mac instances support Enhanced Networking?](#ena)
1.	[Do EC2 Mac instances support live migration?](#live)
1.	[Do EC2 Mac instances support network burst capabilities?](#burst)
1.	[Do EC2 Mac instances support Intel virtualization features, such as VT-d and VT-x?](#virt)

---
1. <a name="release">**How do you release a dedicated host?**</a>

    The minimum allocation period for an EC2 Mac Dedicated Host is 24 hours. After the allocation period has exceeded 24 hours, first stop (or terminate) the instance running on the host, then release the host using the `aws ec2 release-hosts` CLI command or the AWS Management Console. 

1. <a name="one-to-one">**How many Mac instances can be supported on a Mac dedicated host?**</a>

    EC2 Mac instances are enabled as bare metal; Only one instance is supported on a single dedicated host at a time.

1. <a name="ram">**Can you share Mac dedicated hosts with other AWS accounts in your organization?**</a>

    Yes. You can share Mac dedicated hosts with AWS accounts inside your AWS organization, an organizational unit inside your AWS organization, or your entire AWS organization via AWS Resource Access Manager. For more information, please refer to the AWS Resource Access Manager documentation.


1. <a name="amis">**What macOS AMIs are available?**</a>

    The latest versions of following macOS operating systems are available as AMIs in regions where EC2 Mac instances are available: 
    a.	macOS Mojave (10.14.x)
    b.	macOS Catalina (10.15.x) 
    c.  macOS Big Sur (11.x)
    
    EC2 Mac instances are based on the 2018 Mac mini, which means Mojave is as 'far back' as you can go, since the 2018 Mac mini shipped with Mojave and Apple hardware only supports the macOS version shipped with the hardware or later.
    * For older macOS versions, you can run a <a name="virt">type-2 virtualization layer</a> (e.g. VMware Fusion, Parallels, [Anka](https://aws.amazon.com/blogs/compute/getting-started-with-anka-on-ec2-mac-instances/)) to get access to High Sierra or Sierra.
    * For future macOS versions, you can do in-place upgrades on EC2 Mac to the new release until AWS vended AMI is available. Running beta versions is not recommended; we propose customers to <a name="cadence">wait the release goes GA</a> before doing an in-place upgrade.

1. <a name="userdata">**How do you pass user data or automated configurations to an EC2 Mac instance?**</a>

    Just like EC2 Linux instances, you can pass custom user data to EC2 Mac instances either as cloud-init directives or as shell scripts. You can also pass this data into the launch wizard as plain-text, as a file, or as a base64-encoded-text.

1. <a name="connect">**How do you connect to EC2 Mac instances?**</a>

    There are multiple ways to connect to EC2 Mac instances:
    •	SSH access via an EC2 Key Pair
    •	Command line access via the SSM Agent
    •	VNC access over an SSH tunnel using the macOS built-in VNC server

1. <a name="remote">**How do you connect via remote screen sharing to an EC2 Mac instance?**</a>
    You can enable remote screen sharing on an EC2 Mac instance by activating built-in VNC server via the command line, and then using a local VNC client to connect over an SSH tunnel.

1. <a name="xcode">**How do you install Xcode on an EC2 Mac instance?**</a>

    AWS provides base macOS AMIs without any prior Xcode installation. You can install Xcode (and accept the EULA) just like you would on any other macOS system. For example, run xcode-select --install to install the Xcode command line tools (CLT) via Terminal, then log in to the instance using VNC to click on the popup and accept the EULA. You can also install the latest Xcode IDE from the App Store, or earlier Xcode versions from the Apple Developer website. Once you have Xcode installed, we recommend creating a snapshot of your AMI for future use. 

1. <a name="wifi">**Is there Wi-Fi and Bluetooth access on Mac instances?**</a>

    No. There is no access to any Wi-Fi network or Bluetooth devices on EC2 Mac instances.

1. <a name="audio">**Is there access to the microphone input or audio output on an EC2 Mac instance?**</a>

    There is no access to the microphone input on an EC2 Mac instance. The built-in Apple Remote Desktop VNC server does not support audio output. 

1. <a name="nvram">**Can you update the EFI NVRAM variables on an EC2 Mac instance?**</a>

    Yes, you can update certain EFI NVRAM variables on an EC2 Mac instance that will persist across reboots. However, EFI NVRAM variables will be reset if the instance is stopped or terminated. Please see the EC2 Mac instance documentation for more information.

1. <a name="filevault">**Can you use FileVault to encrypt the EBS boot volume on EC2 Mac instances?**</a>

    FileVault requires a login before booting into macOS and before remote access can be enabled. If FileVault is enabled, you will lose access to your data on the boot volume at instance reboot, stop, or terminate. We strongly recommend you do not enable FileVault. Instead, we recommend using Amazon EBS encryption for both boot and data EBS volumes on EC2 Mac instances.

1. <a name="cadence">**What is the release cadence of macOS AMIs?**</a>

    We will make new macOS AMIs available on a best effort basis. You can subscribe to [SNS notifications](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html#subscribe-notifications) for updates. We are targeting 30-60 days after a macOS minor version update and 90-120 days after a macOS major version update to release official macOS AMIs.

1. <a name="amis-elsewhere">**Can you run macOS AMIs anywhere other than EC2 Mac instances?**</a> 

    No, macOS AMIs are only supported to run on EC2 Mac instances, macOS itself will not boot without recognizing underlying Apple hardware.

1. <a name="byo">**Can you bring your own macOS image to run on EC2 Mac instances?**</a>

    No, you cannot bring your own macOS images to run on EC2 Mac instances. However, you can install any macOS applications or software within the AWS provided AMI for subsequent use.

1. <a name="packages">**What agents and packages are included in EC2 macOS AMIs?**</a>

    The following agents and packages are included by default in EC2 macOS AMIs:
    | Package | Description |
    | ------------- |------------- |
    | ENA Driver for macOS | Enhanced networking adapter driver for macOS |
    | AWS CLI | CLI which enables interaction with AWS services |
    | EC2-macos-init | cloud instance initialization  |
    | Amazon CloudWatch Agent | Agent for CloudWatch monitoring |
    | Chrony | Amazon Time Service-compatible NTP |
    | Homebrew | Package manager for macOS |
    | AWS Systems Manger Agent | AWS Systems manager for macOS |

1. <a name="update-packages">**Can you update the agents and packages included in macOS AMIs?**</a>

    There is a public Github repository and Homebrew tap for all agents and packages added to the base macOS image on Amazon EC2 macOS AMIs. This repository documents the kernel tuning parameters for EC2 Mac instances. You can use `brew tap` and `brew install` to install the latest versions of agents and packages on macOS instances. Regular updates to these packages will be done twice a month on the first and third Tuesday of the month. These updates will include all updates to Amazon-owned packages that have been tested and validated. Any security updates will be done on a per-package basis and only for CVEs at the highest level. 

1. <a name="update-os">**Can you apply OS and software updates to your Mac instances directly from Apple Update Servers?**</a>

    Automatic Software Updates will be turned off by default on macOS AMIs. However, you can turn them on to download the latest macOS and Apple Software updates. 

1. <a name="nitro">**Do EC2 Mac instances support the Nitro system?**</a>

    Yes. Amazon EC2 Mac instances are built on and support the Nitro system, a collection of hardware offload and server protection components that come together to provide high performance networking and storage resources to EC2 instances.

1. <a name="ebs-and-eni">**How many EBS volumes and ENIs are supported by EC2 Mac instances?**</a>

    EC2 Mac instances support 16 EBS volumes and 8 ENI attachments. 

1. <a name="ebs">**Do EC2 Mac instances support EBS?**</a>

    EC2 Mac instances are EBS optimized by default and offer up to 10 Gbps of dedicated EBS bandwidth to both encrypted and unencrypted EBS volumes.

1. <a name="hibernation">**Do EC2 Mac instances support on-demand and spot hibernation?**</a>

    No. EC2 Mac instances do not support on-demand or spot hibernation. EC2 Mac instances are offered as bare metal instances on dedicated hosts.

1. <a name="instance-storage">**Do EC2 Mac instances support booting from instance storage?**</a>

    No. Mac instances can only be booted from EBS-backed macOS AMIs. 
  
1. <a name="recovery">**Do EC2 Mac instances support Auto Recovery or Host Recovery?**</a>

    No. EC2 Mac instances do not support Auto Recovery or Host Recovery. EC2 Mac instances are offered as bare metal instances on dedicated hosts.

1. <a name="groups">**Do EC2 Mac instances support Placement Groups?**</a>

    No. EC2 Mac instances do not support Placement Groups. EC2 Mac instances are offered as bare metal instances on dedicated hosts.

1. <a name="fsx">**Do EC2 Mac instances support FSx?**</a>

    Yes. EC2 Mac instances support FSx using the SMB protocol. You will need to enroll the EC2 Mac instance into a supported directory service (such as Active Directory or the AWS Directory Service) to enable FSx on EC2 Mac instances. 

1. <a name="efs">**Do EC2 Mac instances support EFS?**</a>

    Yes, EC2 Mac instances support Amazon EFS.

1. <a name="ena">**Do EC2 Mac instances support Enhanced Networking?**</a>

    Mac instances support only ENA-based Enhanced Networking. With ENA, Mac instances can deliver up to 10 Gbps of network bandwidth.

1. <a name="live">**Do EC2 Mac instances support live migration?**</a>

    No, EC2 Mac instances do not support live migration. EC2 Mac instances are offered as bare metal instances on dedicated hosts.

1. <a name="burst">**Do EC2 Mac instances support network burst capabilities?**</a>

    No. EC2 Mac instances do not support network burst capabilities. EC2 Mac instances are offered as bare metal instances on dedicated hosts.

1. <a name="virt">**Do EC2 Mac instances support Intel virtualization features, such as VT-d and VT-x?**</a>

    Yes. x86-based EC2 Mac instances (mac1.metal) support both VT-d and VT-x. EC2 Mac instances are offered as bare metal instances on dedicated hosts.
    
---
