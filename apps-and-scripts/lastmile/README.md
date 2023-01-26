# LastMile

This repository contains LastMile, a script to download updated enrollment profiles from a Jamf mobile device management server, then open and present the acceptance workflow to the user. 

This script was developed at AWS for Amazon EC2 Mac instances to present a demonstration of a complete enrollment workflow to a user, which is secured and prevented from un-enrolling without terminating itself. 

## Getting Started

### AWS Secrets Manager
The main runtime of this script retrieves a secret (credentials/passwords) stored in [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/). This secret (`jamfSecret` in the script) provides values for the Jamf URL (`jamfServerDomain`) and API credentials (`jamfEnrollmentUser`,`jamfEnrollmentPassword`) required to generate the profile. The EC2 instance needs an appropriate IAM profile applied to itself to read these secrets, as well.

The Jamf API user account for LastMile *only* requires the **Create** permission for **Computer Invitations**, and none else. See below for an example of an IAM instance profile including the allowed appropriate access.

### EC2 Instance User Data
To start using LastMile, the code from UserData.sh would be pasted into your instance's [User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) before it starts. When the instance starts, it installs a LaunchAgent and downloads the code in [Main.scpt](Main.scpt) to /Users/Shared/.LastMile/Main.scpt, which ensures the user is presented with a prompt to complete enrollment: press the button (or double-click for macOS 13+) and enter the instance's admin credentials. 

### SkyHook
Once this is complete, a LaunchAgent called SkyHook ensures the instance stays enrolled: if it leaves management, the instance stops immediately as an additional layer of security. In order for an instance to take advantage of SkyHook, it will need an Identity and Access Managment (IAM) instance profile attached to it—in addition to permissions to Secrets Manager above—for an instance to stop itself. For appropriate permissions, a profile would look similar to the below example, which can also be used in CloudFormation and Terraform templates to automate the creation of instances. 

---
**Please ensure that you have:** replaced the sample ARN (starting with **⚠️⇢**) with the ARN of **your associated secret**, within the quotes: 

(e.g. `"arn:aws:secretsmanager:aws-region-name:111122223333:secret:secret-abcdef01234567890"`)

*Do not include the ⚠️⇢ as part of the string.*

---


```{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Self-Stop",
            "Effect": "Allow",
            "Action": "ec2:StopInstances",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "aws:userid": "*:${ec2:InstanceID}"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
                "⚠️⇢arn:aws:secretsmanager:aws-region-name:111122223333:secret:secret-abcdef01234567890"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:ListSecrets",
            "Resource": "*"
        }    ]
}
```



*NOTE: Terminating an instance may result in data loss if an instance's storage is ephemeral, which is the default setting. Code to both terminate and snapshot a running instance to preserve the data in a separate AMI are commented out, and will have configurable options in future versions.*
