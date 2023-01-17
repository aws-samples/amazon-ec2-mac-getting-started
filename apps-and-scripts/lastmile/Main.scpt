--LastMile
--AppleScript to prepare an updated profile for manual user completion.
--Includes SkyHook, a LaunchDaemon to auto-stop unenrolled instances.
--With massive thanks to Chad at Alectrona, Chris Potrebka from Wipro, and Mike Gillespie and Sebastien Stormacq at AWS!

--Jamf management username and password: used for initial SSH, change as needed here. Password is auto-generated.
set managementUser to "_LastMile"
set managementPass to (do shell script "uuidgen")
set expirationDate to (do shell script "date -v+2d +\"%Y-%m-%d %H:%M:%S\"")


--Subroutines that are called later in the script start here.

--For adding "https://" and terminating "/" to URLs.
on tripleDouble(incomingURL)
	set incomingURL to (do shell script "echo " & quoted form of incomingURL & " | sed s/[^[:alnum:]%/:+._-]//g | xargs")
	set URLPrepend to "https://"
	if incomingURL does not contain URLPrepend then
		if incomingURL does not contain "http://" then
			if incomingURL does not contain "." then
				display dialog "Invalid URL"
			end if
			set outgoingURL to URLPrepend & incomingURL
		end if
	else
		set AppleScript's text item delimiters to "//"
		set outgoingURL to URLPrepend & (text item 2 of incomingURL)
		set AppleScript's text item delimiters to "//"
	end if
	if outgoingURL does not end with "/" then
		set outgoingURL to (outgoingURL & "/")
	end if
	return outgoingURL as string
end tripleDouble

--Subroutine for retrieving region and credentials from AWS Secrets Manager.
on awsMD(MDPath)
	set sessionToken to (do shell script "curl -X PUT http://169.254.169.254/latest/api/token -s -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600'")
	set MDReturn to (do shell script "curl -H 'X-aws-ec2-metadata-token: " & sessionToken & "' -s http://169.254.169.254/latest/meta-data/" & MDPath)
	return MDReturn
end awsMD

--The subroutine itself, called later as "my retrieveSecret("myAWSregion","mySecretIdentifier","mySecretKey").
--If using separately, passing null to secretQueryKey will return a list of all key/value pairs in a secret.
on retrieveSecret(secretRegion, secretID, secretQueryKey)
	set pathPossibilities to "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin"
	set secretReturn to (do shell script "PATH=" & pathPossibilities & " ; aws secretsmanager get-secret-value --region " & secretRegion & " --secret-id " & secretID & " --query SecretString")
	set AppleScript's text item delimiters to "\"{\\\""
	set secretBlob to text item 2 of secretReturn
	if secretBlob contains "\\\",\\\"" then
		set multiSecret to {}
		set secretKeyList to {}
		set secretValueList to {}
		set AppleScript's text item delimiters to "\\\",\\\""
		repeat with i from 1 to (count text items of secretBlob)
			copy (text item i of secretBlob) to the end of multiSecret
		end repeat
		repeat with secretCount from 1 to (count multiSecret)
			set activeBlob to item secretCount of multiSecret
			set AppleScript's text item delimiters to "\\\":"
			set {secretKey, secretValue} to text items of activeBlob
			set AppleScript's text item delimiters to "\\\""
			set secretValue to text item 2 of secretValue
			if secretCount is equal to (count multiSecret) then
				set AppleScript's text item delimiters to "\\\"}"
				set secretValue to text item 1 of secretValue
			end if
			set AppleScript's text item delimiters to ""
			if secretQueryKey is not null then
				if secretKey is secretQueryKey then
					return secretValue
					exit repeat
				end if
			else
				copy secretKey to the end of secretKeyList
				copy secretValue to the end of secretValueList
			end if
		end repeat
		return {secretKeyList, secretValueList}
	else
		set AppleScript's text item delimiters to "\\\":"
		set {secretKey, secretValue} to text items of secretBlob
		set AppleScript's text item delimiters to "\\\"}"
		set secretValue to text item 1 of secretValue
		set AppleScript's text item delimiters to "\\\""
		set secretValue to text item 2 of secretValue
		set AppleScript's text item delimiters to ""
		return {secretKey, secretValue}
	end if
end retrieveSecret

--Used to retrieve an up-to-date Jamf enrollment profile for the instance. If not using Jamf, you can leave this alone (as it won't be called) as long as the block below about Jamf enrollment is also commented out. The script expects the enrollment profile in /tmp/ as enrollmentProfile.mobileconfig in that case, so make sure one's there if so.
on jamfEnrollmentProfile(jamfInvitationID, jamfEnrollmentURL)
	set payloadUUID to (do shell script "uuidgen | tr [A-Z] [a-z]")
	set payloadIdentifier to (do shell script "uuidgen")
	set profileReturn to "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>PayloadUUID</key><string>" & payloadUUID & "</string><key>PayloadOrganization</key><string>JAMF Software</string><key>PayloadVersion</key><integer>1</integer><key>PayloadIdentifier</key><string>" & payloadIdentifier & "</string><key>PayloadDescription</key><string>MDM Profile for mobile device management</string><key>PayloadType</key><string>Profile Service</string><key>PayloadDisplayName</key><string>MDM Profile</string><key>PayloadContent</key><dict><key>Challenge</key><string>" & jamfInvitationID & "</string><key>URL</key><string>" & jamfEnrollmentURL & "/enroll/profile</string><key>DeviceAttributes</key><array><string>UDID</string><string>PRODUCT</string><string>SERIAL</string><string>VERSION</string><string>DEVICE_NAME</string><string>COMPROMISED</string></array></dict></dict></plist>"
	return (profileReturn) as string
end jamfEnrollmentProfile

--Subroutines end here, main script runtime begins.

try
	set enrollmentCLI to (do shell script "/usr/bin/profiles status -type enrollment | awk '/MDM/' | grep 'enrollment: Yes' ")
on error
	set enrollmentCLI to null
end try
if enrollmentCLI is null then
	
	--------BEGIN JAMF PROFILE ROUTINES--------
	
	--Retrieve credentials for Jamf enrollment from AWS Secrets Manager.
	set currentRegion to (my awsMD("placement/region"))
	set jamfServerDomain to my retrieveSecret(currentRegion, "jamfSecret", "jamfServerAddress")
	set SDKUser to my retrieveSecret(currentRegion, "jamfSecret", "jamfEnrollmentUser")
	set SDKPassword to my retrieveSecret(currentRegion, "jamfSecret", "jamfEnrollmentPassword")
	
	
	--Formats Jamf server address for invitation XML payload.
	set jamfServerAddress to (my tripleDouble(jamfServerDomain))
	
	--Assemble the XML payload.
	set invitationXML to "<computer_invitation><invitation_type>DEFAULT</invitation_type><expiration_date>" & expirationDate & "</expiration_date><ssh_username>" & managementUser & "</ssh_username><ssh_password>" & managementPass & "</ssh_password><multiple_users_allowed>false</multiple_users_allowed><create_account_if_does_not_exist>true</create_account_if_does_not_exist><hide_account>true</hide_account><lock_down_ssh></lock_down_ssh><enrolled_into_site><id></id><name></name></enrolled_into_site><keep_existing_site_membership></keep_existing_site_membership><site><id></id><name></name></site></computer_invitation>"
	
	--Performs API call to receive invitation code.
	set targetResponseCode to (do shell script "curl -sH \"Accept: application/xml\" -H \"Content-Type: application/xml\" " & jamfServerAddress & "JSSResource/computerinvitations/id/id0 -X POST -d '" & invitationXML & "' -ksu \"" & SDKUser & "\":\"" & SDKPassword & "\"")
	
	--Parse output to grab the code alone.
	set AppleScript's text item delimiters to "<invitation>"
	set invitationIDTransitory to text item 2 of targetResponseCode
	set AppleScript's text item delimiters to "</"
	set invitationID to text item 1 of invitationIDTransitory
	set AppleScript's text item delimiters to ""
	
	--Use the invitation code to write the formed profile to disk.
	do shell script "echo " & quoted form of (my jamfEnrollmentProfile(invitationID, jamfServerAddress)) & " > /tmp/enrollmentProfile.mobileconfig"
	
	--------END JAMF PROFILE ROUTINES--------
	
	--Opens the profile, bringing the UI notification up.
	do shell script "open /tmp/enrollmentProfile.mobileconfig"
	delay 0.5
	
	--Opens the System Settings/Preferences pane to accept.
	do shell script "open /System/Library/PreferencePanes/Profiles.prefPane"
	
	set skyHookPlistXML to "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>KeepAlive</key>
	<true/>
	<key>EnvironmentVariables</key>
	<dict>
                <key>PATH</key>
                <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin</string>
	</dict>
	<key>Label</key>
	<string>com.amazon.dsx.skyhook.mdm.daemon</string>
	<key>ProgramArguments</key>
	<array>
		<string>sh</string>
		<string>-c</string>
		<string>/usr/bin/profiles status -type enrollment | awk '/MDM/' | grep -q \"enrollment: No\" && /Users/Shared/.SkyHook.sh || touch /Users/Shared/.skyhook.enrolledLast</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>"
	
	set skyHookScript to "#!/bin/sh

### SkyHook runtime occurs when a client is unenrolled. Code as-is will terminate the underlying instance immediately.

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin
MDToken=$(/usr/bin/curl -X PUT http://169.254.169.254/latest/api/token -s -H \"X-aws-ec2-metadata-token-ttl-seconds: 21600\")
currentInstanceID=$(/usr/bin/curl -H \"X-aws-ec2-metadata-token: $MDToken\" -s http://169.254.169.254/latest/meta-data/instance-id)
hostRegion=$(curl -H \"X-aws-ec2-metadata-token: $MDToken\" -s http://169.254.169.254/latest/meta-data/placement/region)
 
echo \"Unenrolled from management: SkyHook stopping instance $currentInstanceID\" > /tmp/skyhookStatus.txt
# Uncomment the below lines to create an EBS snapshot, then terminate the instance: wait time may need to vary, set to 10 minutes below.
# aws ec2 create-snapshot --volume-id $(aws ec2 describe-instances --instance-id $(curl -s  http://169.254.169.254/latest/meta-data/instance-id) | grep \"VolumeId\" | awk {'print $NF'} | tr -d \"\\\",\" )
# sleep 600
# aws ec2 terminate-instances --instance-ids $currentInstanceID --region $hostRegion

aws ec2 stop-instances --instance-ids $currentInstanceID --region $hostRegion


exit 0;"
	
	delay 1
	set macOSVersion to system version of (system info)
	--Instructional text.
	if macOSVersion starts with "13" then
		display dialog "Please double-click the MDM profile in the list, click the \"Install…\" button near the bottom, and enter the administrator password when prompted to complete enrollment. You may be prompted more than once." buttons "OK" default button "OK" with icon 2
	else
		display dialog "Please click the \"Install…\" button on the right side and enter the administrator password to complete enrollment. You may be prompted more than once." buttons "OK" default button "OK" with icon 2
	end if
	
	--Script waits until enrollment is completed, then (optionally) launches a SkyHook LaunchDaemon to auto-terminate the instance if it becomes unenrolled.
	repeat
		try
			set enrollmentCLI to (do shell script "/usr/bin/profiles status -type enrollment | awk '/MDM/' | grep 'enrollment: Yes' ")
		on error
			delay 4
			set enrollmentCLI to null
		end try
		if enrollmentCLI is null then
			delay 1
		else
			delay 1
			try
				display notification "Thank you for enrolling! Please enter your password one more time to complete installation."
				delay 1
				do shell script "echo '" & skyHookPlistXML & "' > /tmp/com.amazon.dsx.skyhook.mdm.daemon.plist" with administrator privileges
				do shell script "mv /tmp/com.amazon.dsx.skyhook.mdm.daemon.plist /Library/LaunchDaemons/com.amazon.dsx.skyhook.mdm.daemon.plist" with administrator privileges
				do shell script "echo '" & skyHookScript & "' > //Users/Shared/.SkyHook.sh ; chmod +x /Users/Shared/.SkyHook.sh" with administrator privileges
				do shell script "chown root:wheel /Library/LaunchDaemons/com.amazon.dsx.skyhook.mdm.daemon.plist" with administrator privileges
				do shell script "launchctl load -w /Library/LaunchDaemons/com.amazon.dsx.skyhook.mdm.daemon.plist" with administrator privileges
				display notification "Enrollment complete! Profiles and policies will begin to apply shortly."
			on error
				display notification "Enrollment complete! Profiles and policies should begin to apply shortly.
		
		For Admin: SkyHook daemon did not complete installation."
			end try
			
			--Finally LastMile unloads its own LaunchAgent.
			try
				do shell script "launchctl unload -w /Library/LaunchAgents/com.amazon.dsx.lastmile.startup.plist"
			end try
			exit repeat
		end if
	end repeat
else
	log "Instance already enrolled."
end if
