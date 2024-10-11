# An Introduction to Developing Apps & Scripts with EC2 Mac

### Please note: [`enroll-ec2-mac` is available for automated MDM enrollment on EC2 Mac.](https://github.com/aws-samples/amazon-ec2-mac-mdm-enrollment-automation)

---

#### Join the AWS team live and in-person!
* Check out the [EC2 Mac session at the upcoming Jamf Nation User Conference (JNUC) 2024!](https://reg.jnuc.jamf.com/flow/jamf/jnuc2024/sessioncatalog2024/page/sessioncatalog/session/1715273365922001uWTL)

Hi! We’re glad to have you here. We want to share how Amazon EC2 Mac instances (we’ll get into what that means further down) allow you to accelerate your workflow and accomplish things that have ranged from challenging to near-impossible without foresight. Specifically, we’ll focus on how EC2 Mac instances let you:

  * Access a Mac to develop and test with whenever you might need one — [*within minutes.*](#im-in-what-about-access-to-the-gui-though)
  * Switch between multiple macOS versions effortlessly — [*on the same Mac.*](#imaging)
  * Recreate user scenarios — [*in a safe, ephemeral, non-virtualized macOS environment.*](instance)
  * Test your macOS scripts and apps easily — [*before they hit production.*](#thats--cool-but-what-can-i-do-that-i-couldnt-do-before)
  * Build, test, sign, and publish your Apple apps in the cloud — [*forget the Mac-in-a-closet (or under a desk).*](#my-apps-and-automations-are-getting-more-complex-what-about-development)
  * And, of course, integrate with device management solutions like Jamf to enroll and test complex workflows — [*before they deploy to your users.*](#cool-now-how-does-it-fit-in-with-jamf)

On that last one: this workflow is thanks to our recent partnerships—see the recent announcement by AWS and Jamf **[here](https://www.jamf.com/resources/press-releases/jamf-works-with-aws-to-manage-and-provide-an-added-layer-of-security-to-amazon-ec2-mac-instances-at-scale/)** and the launch blog by Jamf, Wipro, and AWS **[here](https://aws.amazon.com/blogs/apn/automate-the-enrollment-of-ec2-mac-instances-into-jamf-pro/)**. MDM enrollment can now automatically occur when an instance starts. The process involves a script and light image setup, with full setup instructions and templates [here.](https://github.com/aws-samples/amazon-ec2-mac-mdm-enrollment-automation)


<a href="http://www.youtube.com/watch?feature=player_embedded&v=q7wDxF0bLFY" target="_blank"><img src="https://github.com/aws-samples/amazon-ec2-mac-getting-started/raw/main/img/m1_and_lastmile_preview.png" width="800" alt="YouTube preview of Amazon EC2 Mac M1 and script LastMile"/></a>

---
#### If you are an experienced user in AWS, awesome! **[Check out our guide to starting your first EC2 Mac instance here!](https://github.com/aws-samples/amazon-ec2-mac-getting-started/blob/main/ec2-macos.md)**

#### If you’re not experienced in AWS, or don’t speak cloud at all, **you’re still awesome!** Let’s dive deeper together below on what we have to offer, starting with the name: EC2 Mac. ⬇️
---


## EC2 and You

EC2 stands for Elastic Compute Cloud, and is Amazon’s offering for compute in the cloud.

## Compute?

Yup, like a computer—that is available on-demand, accessible over the internet, with a pay-as-you-go model.. Let’s narrow our discussion a bit now, just to EC2 Mac.

## OK, so what’s an EC2 Mac?

At its core, an EC2 Mac is an Apple Mac mini, connected to AWS cloud via AWS Nitro System—which provides network, storage, security, and more over Thunderbolt. While this Mac mini is the same as any other Mac mini you’d find off the shelf (see the specs below), the interconnection to AWS Nitro System is what enables you to run powerful Apple workloads in AWS cloud. When you request a Dedicated Host (the first step in getting your EC2 Mac up and running—more on that below), think of it as AWS physically handing that Mac mini to you—releasing the host is you “handing it back.” 

If you’d like (or prefer to) see this all visualized, take a look at our 90-second EC2 Mac explainer video **[here](https://www.youtube.com/watch?v=d0FulqrjHkk)**!

## Dedicated Host?

A new term! A Dedicated Host (sometimes abbreviated DH) is AWS’ way of saying that you, as a customer, have use of a specific piece of hardware: in this case, the aforementioned Mac mini. Think of this as your official “claim” on your Mac in AWS cloud during the time you have it. Once you have your host (or hosts), you’re able to launch an instance onto it.

## Instance?

Another term! An EC2 Mac instance, simply put, is a Mac that’s running in AWS cloud booted from an Amazon Machine Image, or AMI. Think of the AMI like a bootable volume, and an instance as almost a “cousin” to a virtual machine: you can take a new snapshot (which creates a new AMI that you’re able to launch instances of), and that represents everything that’s on the disk at the time. An AMI can be instantly duplicated and used to launch as many EC2 Mac instances as you need, all from the same image. 

## Imaging…

Yes, imaging! While a deprecated practice for general Mac management, it’s again a thing through AMIs! An **Amazon Machine Image (AMI)** is very similar to a monolithic image, or a bootable USB drive. Thanks to AMIs, you can easily test different macOS versions by switching between AMIs on the same EC2 Mac Dedicated Host—*within minutes, and with a single click*. AMIs can be created, or “baked,” *even while an instance is running*, and can be used to start duplicates of itself on other EC2 Mac hosts within minutes.

## You mentioned hardware, what are the specs on these Macs?

As for the EC2 Mac Dedicated Host hardware, there’s a few types available: **Mac1** is a 2018 Mac mini with 12-core x86 and 32GB RAM. Any instance that starts with **Mac2** is an Apple silicon instance: **Mac2** is a 2020 Mac mini with Apple’s M1 chip and 16GB RAM. **Mac2-m2** is a 2023 Mac mini with Apple’s M2 chip and 24GB RAM. **Mac2-m2pro** is a 2023 Mac mini with Apple’s M2 Pro chip and 32GB RAM. The instance you spin up on top of the Dedicated Host adds .metal to the end (e.g. mac1.metal, mac2-m2.metal, etc.). The **metal** in the instance name means that you’re able to use all of the underlying Mac mini hardware without any virtualization layer: bare-metal. 

## That’s  cool, but what can I do that I couldn't do before?

EC2 Mac is more than a Mac mini on a rack in a datacenter. The Apple hardware is bare-metal connected to the **[AWS Nitro System](https://aws.amazon.com/ec2/nitro/)**—a purpose-built, secure system that provides storage and networking over Thunderbolt, along with security and monitoring of the hardware itself. Nitro is responsible for ensuring a Mac Dedicated Host is prepared on-demand, its firmware updated, and all of its storage cleared. Also, Nitro gives you even more detailed insights into monitoring and logs, and is itself, by design, entirely locked off from tampering or admin access. Here’s a picture of what it all looks like together:

![An image of a Mac mini in an AWS Nitro sled in a datacenter.](https://github.com/aws-samples/amazon-ec2-mac-getting-started/raw/main/img/nitro-mac-full-image.png)

On the software side, there’s no shortage of enhancement, either: **[`ec2-macos-init`](https://github.com/aws/ec2-macos-init)** is an open-source helper agent included on the Amazon-vended image that allows you to run scripts or code as soon as the Mac is booted. The stock AMI includes **[Homebrew (`brew`)](https://github.com/Homebrew/brew)** as well, to assist in installation of packages across the internet. The **[AWS Systems Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/what-is-systems-manager.html)** agent is also installed, bringing additional workflow integration, control, and reporting for your instances. **[Read more here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html#ec2-macos-images)** on exactly what’s offered in the Amazon-vended AMI.

In short, an EC2 Mac instance is far more secure than a stray Mac mini under a desk! Now that we have an EC2 Mac instance running on a Dedicated Host, let’s next connect it a network.

## I thought the cloud was a network?

It is! A network of networks, with some more networks inside those. Luckily, there’s not a whole lot to wrestle with to ensure your Mac can meet the internet, or as much (or little) of the internet as you want it to. First, let’s start with the Amazon Virtual Private Cloud, or VPC. A VPC can be thought of as a virtual datacenter: it can encompass many subnets, and it also allows you to privately connect your datacenter to another one with minimal configuration. 

If you’re just getting started with EC2 Mac, when you create your EC2 account, a default VPC is created in the Region your instance starts up in. Its default state is enough for what we’ll need to do to get started. 

## AWS Regions (and Availability Zones)?

The AWS cloud is divided into physical regions, which are subdivided into Availability Zones, or AZs for short. See the diagram below: a region is made of many AZs, and each AZ itself is redundant too, made of multiple datacenters. **[See here for a comprehensive list of all regions and AZs.](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/)**

![A diagram displaying AWS Region and Availability Zone layout.](https://raw.githubusercontent.com/aws-samples/amazon-ec2-mac-getting-started/main/img/aws_region_design_diagram.png)

* **x86-based EC2 Mac instances** are available across the following AWS Regions: US East (N. Virginia, Ohio), US West (Oregon), Europe (Ireland, Frankfurt, London, Stockholm), and Asia Pacific (Singapore, Seoul, Tokyo, Mumbai, and Sydney). 

* **M1-based EC2 Mac instances** are available across the following AWS Regions: US East (N. Virginia, Ohio), US West (Oregon), Europe (Ireland), and Asia Pacific (Singapore).

* **M2-based EC2 Mac instances** are available across the following AWS Regions: US East (N. Virginia, Ohio), US West (Oregon), Europe (Frankfurt), and Asia Pacific (Sydney).

* **M2 Pro-based EC2 Mac instances** are available across the following AWS Regions: US East (N. Virginia, Ohio), US West (Oregon), and Asia Pacific (Sydney).

## Now there’s something about a security group.

Security Groups can be thought of as firewalls: they’ll keep any incoming connections out unless you specify. When you’re launching your EC2 Mac instance, you can automatically create a group that’ll keep anything but port 22 out, which we can use to SSH (and later VNC) into our Mac. Keep in mind that Security Groups are *stateful*, which means that the Mac itself can still reach out to the internet (without an explicit denial in the rules), and can also accept incoming connections that itself has initiated. All that means a default Security Group is a good place to start. With port 22 open, now you can SSH and connect to your Mac instance!

## I’m in! What about access to the GUI, though?

Once you’re connected to your Mac instance, you can [use SSH to enable VNC access via macOS’ built-in Screen Sharing service.](https://github.com/aws-samples/amazon-ec2-mac-getting-started/blob/main/steps/03_connect_and_enable.md) For enhanced GUI connectivity, check out our [step-by-step blog](https://aws.amazon.com/blogs/apn/amazon-ec2-mac-enhanced-remote-access-with-hp-anyware/) with HP Anyware (formerly Teradici), a macOS agent (x86 available today on [AWS Marketplace](https://aws.amazon.com/marketplace/pp/prodview-isaghmqny2wr6), Apple silicon launching February 2023) enabling secure, compressed, pixel-perfect remote screen sessions. Also, keep in mind, the flexibility of the cloud means there may not be a need to replace on-premises, physical developer devices with cloud EC2 Macs on a one-to-one basis. For example, if you have Apple developers located across geographical regions—great! Using an [auto-scaled shared pool of EC2 Macs](https://aws.amazon.com/blogs/compute/implementing-autoscaling-for-ec2-mac-instances/) for devs across time zones to launch an instance on (and terminate when done) can bring extra savings through the efficiencies gained. If this interests you or you’re ready to get going, let’s talk, as we have some great resources and experience to share—see below how to get in touch!


## Tell me more about security,  my InfoSec guys love that!

Of course! To start, EC2 Mac instances carry all the security that AWS brings; see more **[here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security.html)**. In addition, the Mac host is "yours" for the duration, When you’re done with it (or whenever you’re switching instances), a process occurs called **[scrubbing,](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html#mac-instance-stop)** which securely destroys any data on the Mac, down to restoring the firmware, to remove any possible data that could be left in place. The root volume of the Mac can also be fully AES-256 encrypted, with a key that can be stored and rotated in AWS.

## One other thing: SSH key.

Yes—for security, the AMIs launched do not have a password: they can only be accessed with an SSH key file. In [the step-by-step instructions](https://github.com/aws-samples/amazon-ec2-mac-getting-started/blob/main/ec2-macos.md) we’ll go into how to make one, download the key file, then use it to connect. EC2 Mac instances can be configured, just like any Mac, with multiple users and standard passwords—we’ll actually be setting one in our walkthrough later on in order to connect to the GUI.

## Cool! Now, how does it fit in with Jamf?

AWS announced our partnership with Jamf in mid-2022, starting with **[agent-based enrollment](https://www.jamf.com/resources/press-releases/jamf-works-with-aws-to-manage-and-provide-an-added-layer-of-security-to-amazon-ec2-mac-instances-at-scale/)**, and have added **[support and integration for Jamf Private Access](https://www.jamf.com/resources/press-releases/jamf-announces-new-integration-with-aws/)**. Full automation is now available in [the `amazon-ec2-mac-mdm-enrollment-automation` repository here.](https://github.com/aws-samples/amazon-ec2-mac-mdm-enrollment-automation)

## My apps and automations are getting more complex, what about development?

Awesome! Many builders and admins are finding that scripting is the start of their automation journey, and are picking up more compiled languages like **[Swift](https://aws.amazon.com/sdk-for-swift/)** to expand their optimizations in ways they never have before. Building, testing, signing, and publishing apps is **[something EC2 Mac is great for, and was built for](https://aws.amazon.com/blogs/compute/unify-your-ios-mobile-app-ci-cd-pipeline-with-amazon-ec2-mac-instances-2/)**—so it’s easily integrated into common developer CI/CD workflows. 

## OK, so now I get how this works. How much is it?

Apple’s **[macOS EULA](https://www.apple.com/legal/sla/)** defines a minimum 24-hour initial lease period. Simply put, when you allocate an EC2 Mac Dedicated Host, a 24-hour timer will start. After the 24-hour initial lease time has elapsed, you are free to release the host back to AWS whenever you’re done: the AWS billing stops that very second. 

The per-second AWS charge on the EC2 Mac Dedicated Host is the only charge: there’s no secondary “lease charge” or charge to run an instance. Additional charges may apply for storage, snapshots, and data transfer as well, with that info [here](https://aws.amazon.com/ebs/pricing/) and **[here](https://aws.amazon.com/ec2/pricing/on-demand/#Data_Transfer)**. EC2 Mac pricing (per-region) can be found on **[this page](https://aws.amazon.com/ec2/dedicated-hosts/pricing/)** for both On-Demand usage and Savings Plan. 

## Awesome, I want to build this! What should I do next? 

Great! Our EC2 Mac step-by-step guide is [here](https://github.com/aws-samples/amazon-ec2-mac-getting-started/blob/main/ec2-macos.md). 

## I don’t really get it. Or, I’d like to learn more! 

Feel free to get in touch with us if you’re stuck at any point or want to influence what AWS and our partners should be building next by **[opening a GitHub issue](https://github.com/aws-samples/amazon-ec2-mac-getting-started/issues/new/choose)**, creating a **[re:Post](https://repost.aws/)** with the tag **#ec2mac**, or reaching out via **[email](mailto:ec2-mac-wwso@amazon.com)**.

