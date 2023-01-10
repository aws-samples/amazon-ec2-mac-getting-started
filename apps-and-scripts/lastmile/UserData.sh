#!/bin/sh

### LastMile
### A script to download a profile and prompt a user to complete device enrollment.

# ### Setting PATH variable for calling command line utilities like Homebrew (brew) and the AWS CLI (aws).
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin

### This LaunchAgent will auto-start the runtime script at login, which is written further down.
LastMileLaunchAgent='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>KeepAlive</key>
	<false/>
	<key>LimitLoadToSessionType</key>
	<string>Aqua</string>
	<key>Label</key>
	<string>com.amazon.dsx.lastmile.startup</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/bin/osascript</string>
		<string>/Users/Shared/.LastMile/Main.scpt</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>'

### Formats, writes, and runs the LaunchAgent to start LastMile on login.
echo "$LastMileLaunchAgent" | xmllint --format - > /tmp/com.amazon.dsx.lastmile.startup.plist
sudo mv /tmp/com.amazon.dsx.lastmile.startup.plist /Library/LaunchAgents/com.amazon.dsx.lastmile.startup.plist
sudo chown root:wheel /Library/LaunchAgents/com.amazon.dsx.lastmile.startup.plist

### The directory and code for the LastMile AppleScript runtime, written to /Users/Shared/.LastMile/Main.scpt. 
### URI will need to be adjusted: the cURL example will take the default Main.scpt from the GitHub repository.
### Sample of a custom runtime hosted on Amazon Simple Storage Service (S3) download through the AWS CLI commented out below.

mkdir -p /Users/Shared/.LastMile/
curl https://raw.githubusercontent.com/aws-samples/amazon-ec2-mac-getting-started/mac-admin/apps-and-scripts/lastmile/Main.scpt -o /Users/Shared/.LastMile/Main.scpt
# aws s3 cp s3://DOC-EXAMPLE-BUCKET/LastMile.scpt /Users/Shared/.LastMile/Main.scpt

### Setup continues here: change the written script to executable.
chmod +x /Users/Shared/.LastMile/Main.scpt

### Load the LaunchAgent (which loads the script). 
### Not necessary if the command after this runs to log out the user.
activeUser=$(stat -f '%u %Su' /dev/console | awk '{print $1}')
launchctl asuser $activeUser launchctl load -w /Library/LaunchAgents/com.amazon.dsx.lastmile.startup.plist

exit 0;
