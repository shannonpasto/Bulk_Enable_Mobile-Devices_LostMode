#!/bin/sh

####################################################################################################
#
# Copyright (c) 2015, JAMF Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################

###################
# bulk_enable_mobile-devices_lostmode-classic.sh - script to bulk enable lost mode for mobile devices via the classic API
# Shannon Pasto https://github.com/shannonpasto/Bulk_Enable_Mobile-Devices_LostMode
#
# v1.0 (14/11/2025)
###################

## uncomment the next line to output debugging to stdout
#set -x

###############################################################################
## variable declarations

# Jamf Pro administrator user
username="username"
# Jamf Pro administrator user's password
password='password'
# replace 'instance' with your unique Jamf Pro instance URL
url="https://youinstance.jamfcloud.com"
# Id of the smart or static mobile device group
groupID="1"
# set these to be displayed on the mobile device
lost_mode_message="This device has been reported as lost and its location has been identified, please return before authorities arrive."
lost_mode_phone="555-555-5555"
lost_mode_footnote="This is an optional footnote"
always_enforce_lost_mode="false"  # set to true to re-enable lost mode
lost_mode_with_sound="false"  # set to true to play a sound

###############################################################################
## function declarations

###############################################################################
## start the script here

########################################
###### DON'T EDIT BELOW THIS LINE ######
########################################

# Create base64-encoded credentials
encodedCredentials=$(printf '%s:%s' "${username}" "${password}" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i -)

# Generate an auth token
token=$(/usr/bin/curl -sk "${url}/api/v1/auth/token" -X POST -H "Authorization: Basic ${encodedCredentials}" | /usr/bin/jq -r '.token')

# send the command to activate lost mode
for theID in $(/usr/bin/curl -s -X 'GET' "${url}/JSSResource/mobiledevicegroups/id/${groupID}" -H 'accept: application/xml' -H "Authorization: Bearer ${token}" | /usr/bin/xmllint --xpath '//mobile_device_group/mobile_devices/mobile_device/id/text()' -); do
  /usr/bin/curl -s "${url}/JSSResource/mobiledevicecommands/command" -H'Content-Type: application/xml' -H "Authorization: Bearer ${token}" \
--data "<mobile_device_command>
	<general>
		<command>EnableLostMode</command>
		<lost_mode_message>${lost_mode_message}</lost_mode_message>
		<lost_mode_phone>${lost_mode_phone}</lost_mode_phone>
		<lost_mode_footnote>${lost_mode_footnote}</lost_mode_footnote>
		<always_enforce_lost_mode>${always_enforce_lost_mode}</always_enforce_lost_mode>
		<lost_mode_with_sound>${lost_mode_with_sound}</lost_mode_with_sound>
	</general>
	<mobile_devices>
		<mobile_device>
			<id>${theID}</id>
		</mobile_device>
	</mobile_devices>
</mobile_device_command>"
  sleep 1
done

# invalidate the token
/usr/bin/curl -s -X POST "${url}/api/v1/auth/invalidate-token" -H "Authorization: Bearer $token"
