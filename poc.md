## **EC2 Mac Instances Proof-Of-Concept (PoC) Guide**
---
Interested in a formal Proof-Of-Concept of EC2 Mac instances? Awesome!

Here's some tips from our experiences - please feel free to [open an issue](https://github.com/aws-samples/amazon-ec2-mac-getting-started/issues/new/choose) or even [submit a PR](https://github.com/aws-samples/amazon-ec2-mac-getting-started/compare) if you'd like to add yours!

---

#### High-level steps to ensure a successful PoC:
* Determine PoC duration and timing, ensuring all team members have schedule availability to put towards evaluing EC2 Mac.
* Determine success criteria, what you'd like to see from EC2 Mac compared to existing systems. Depending on the length of the PoC, these may include interim milestones. 
* Schedule cadence calls and/or email reports with the larger team to discuss progress and any concerns that may arise.
* _To your AWS Account Team_: Confirm the AWS account ID and region you would like to use for the POC. AWS will ensure the account’s soft quota limit in that region is sized for your PoC and beyond.
* _To your AWS Account Team_: Confirm the potential capacity (number of EC2 Mac instances) needed in which regions for the PoC - and for any production workloads post-PoC. AWS would like to capture this to drive EC2 Mac capacity planning across our global regions and on-going expansion. 

#### A typical technical PoC workflow:
  * Identify [Regions and AZs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html#mac-instance-considerations) for PoC, and communicate those to your AWS Account Team.
  * Identify macOS version(s) and Xcode version(s) needed
  * Identify CI/CD tooling needed ([Jenkins, Fastlane, etc.](https://aws.amazon.com/blogs/compute/unify-your-ios-mobile-app-ci-cd-pipeline-with-amazon-ec2-mac-instances-2/))
  * Identify size (in GB) and throughput (in IOPs) of [boot volume](https://aws.amazon.com/ebs/volume-types/) needed
  * Start with our vended AMI, configure as necessary, then [create a derivative AMI](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/creating-an-ami-ebs.html) ([alternatively, use Packer](https://aws.amazon.com/blogs/compute/building-amazon-machine-images-amis-for-ec2-mac-instances-with-packer/))
  * Determine any dynamic configuration needed via [ec2-macos-init](https://github.com/aws/ec2-macos-init)
  * [Allocate host(s)](steps/01_allocate_host.md), [launch instance(s)](steps/02_launch_instance.md), and [test it out!](03_connect_and_enable.md)

#### A quick note about scrubbing:
 
After every stop/terminate of EC2 Mac instances, we run a _scrubbing workflow_ that sanitizes the internal SSD, clears NVRAM variables, and optionally updates the [bridgeOS](https://en.wikipedia.org/wiki/BridgeOS) on the underlying Mac mini’s T2 chip if needed. This ensures that EC2 Mac instances have the same security bar as other Nitro instances. In addition, you don’t need to worry about keeping bridgeOS up-to-date to run the latest macOS AMIs. During this scrubbing process, the EC2 Mac Dedicated Host itself goes into a _pending_ state, and can take 40-65 minutes to complete (or ~3 hours if bridgeOS update is required).

During this scrubbing period, when the Dedicated Host goes into _pending_ state – AWS metering and billing stops, and you aren't charged for that duration. (The pending state does count towards the 24-hour minimum allocation time, however.) 
  
<!-- TODO: Add Type-2 Virtualization here -->


