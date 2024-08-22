# Getting started with EC2 Mac Instances

DRAFT

* Intro

Automating Amazon Web Services Elastic Compute Cloud (EC2) instances in general comes with many options, and automating EC2 Mac instances are no different. If you’ve used EC2 before, you may be familiar with the concept of *instances*. An instance is, in most cases, a virtual machine that’s started from an image of your choosing or creation, which can be started or stopped on-demand as needed. If you're a Mac admin more familiar with Jamf than AWS, check out this link<> with more information on EC2 Mac in general.

EC2 Mac is different from other EC2 instance types in that it *requires* its instances to be run on Dedicated Hosts. A dedicated host is what it sounds like: compute—in this case a Mac mini or Mac Studio—the resources of which are entirely available for you to use, without sharing with other tenants. In EC2 Mac’s case, this is driven by requirements in the Apple Software Licensing Agreement, which states a Mac can only be leased to a single entity for a minimum of 24 hours. While this means an EC2 Mac isn’t subdivided, it also means that you have the ability to do anything you can do with a physical Mac: install different versions of macOS, run type-2 virtual machines, and even disable System Integrity Protection. 

We’re going to cover the commands generally in order, but running every one below won’t result in success: make sure you’re reading what the command does before you send it, as data could be lost or unused resources left in active billing.

If you prefer a video you can follow along with using the AWS Console, one is available at this link. <>


### Managing hardware

EC2 Mac instances have, at their heart Apple hardware: Mac mini or Mac Studio devices, connected to AWS Nitro<> via Thunderbolt and fully managed. The only action you as an end user need to take is when to take possession or release an EC2 Mac host. 

> :warning: Note: when allocating an EC2 Mac host, **billing will begin**. Billing will complete when the EC2 Mac host is **released**, with a **minimum of 24 hours allocation** as per Apple’s macOS software license agreement. For more info on billing, click here<>

We’re going to have examples in a few formats for each of these, but the variables largely remain the same from one format to another. 


#### Allocate a host

```bash
EC2Region="us-east-1"
EC2AvailabilityZone="a"
EC2AZ="$EC2Region$EC2AvailabilityZone"
EC2InstanceType="mac2-m2.metal"
aws ec2 allocate-hosts --availability-zone $EC2AZ --auto-placement 'on' --host-recovery 'off' --quantity 1 --tag-specifications 'ResourceType=dedicated-host,Tags=[{Key=Name,Value=MacHost}]' --instance-type $EC2InstanceType
```
You’ll receive the following return (the EC2 host ID):

```json
{
    "HostIds": [
        "h-04e6709f08dad31c6"
    ]
}
```
We can take that host ID into the next step, or, since our example had auto placement turned on, start our instance without specifying a host. We need to define an AMI in this step too, which version of macOS to boot our host with. An instance is booted onto a host: think of it like plugging a USB boot drive into a Mac, then choosing which system to boot from. The AMI in this example is macOS Sonoma 14.6.1. In this example, we are associating a public IP address so we can connect to the GUI over the internet.

```bash
EC2InstanceName="MacInstance"
EC2AMIID="ami-083104674423416b8"
EC2KeyPairName="my-demo-key"
aws ec2 run-instances --region=$EC2Region \
  --instance-type=$EC2InstanceType \
  --image-id=$EC2AMIID --key-name=$EC2KeyPairName \
  --associate-public-ip-address \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$EC2InstanceName}]" \
  --placement='Tenancy'='host'
```

## Things to consider

When stopping or terminating an EC2 Mac instance, it goes through a thorough scrubbing procedure to ensure that none of the data from your current instance could be read by the next instance started onto the hardware, including a full wipe of the SSD and any firmware parameters. This process can take 45 minutes to 3 hours on an Apple silicon instance (instance types starting with mac2), and during this time, **billing is suspended.** When the scrubbing procedure completes, the dedicated host's status will change from **Pending** to **Available**, visible in the AWS console or through the CLI/API via `aws ec2 describe-host-status`

## Release your hosts!

If a host is sitting in your account, unless it is in the 


* Managing hardware:
    * AWS CLI w/samples
        * Allocate/Release
            * Lambda releaser? Could come with the info about billing wrt instance running status
        * Start/Stop/Terminate
        * Connect (SSH,` instance-connect open-tunnel` with documented ports[!!!])
        * SIP disable
    * CDK?
    * API?
    * CloudFormation
        * Host/Instance
        * ASG? Maybe LM/Instance?
* Managing config
    * RRV
    * OrbitalVelocity/in-place OS upgrades
    * OrbitalCluster/MDM
    * ASG (link?)


