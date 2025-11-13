#!/bin/sh

###################
# bulk_enable_mobile-devices_lostmode-pro.sh - script to bulk enable lost mode for mobile devices via the pro API
# Shannon Pasto https://github.com/shannonpasto/Bulk_Enable_Mobile-Devices_LostMode
#
# v1.1 (14/11/2025)
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
play_lost_mode_sound="false"  # set to true to play the lost mode sound

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
if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 24 ]; then
  token=$(/usr/bin/curl -sk "${url}/api/v1/auth/token" -X POST -H "Authorization: Basic ${encodedCredentials}" | /usr/bin/jq -r '.token')
else
  token=$(/usr/bin/curl -sk "${url}/api/v1/auth/token" -X POST -H "Authorization: Basic ${encodedCredentials}" | /usr/bin/plutil -extract token raw -o - -)
fi

build the list
if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 24 ]; then
  manIDList=$(/usr/bin/curl -X 'GET' "${url}/api/v2/mobile-devices/detail?section=GENERAL&page=0&page-size=100&sort=displayName%3Aasc&filter=groupId%3D%3D${groupID}" -H 'accept: application/json' -H "Authorization: Bearer ${token}" | /usr/bin/jq -r '.results[].general.managementId')
else
  manIDList=$(/usr/bin/curl -X 'GET' "${url}/api/v2/mobile-devices/detail?section=GENERAL&page=0&page-size=100&sort=displayName%3Aasc&filter=groupId%3D%3D${groupID}" -H 'accept: application/json' -H "Authorization: Bearer ${token}" | /usr/bin/grep managementId | /usr/bin/cut -d \" -f 4 -)
fi

# send the command to activate lost mode
for theManID in ${manIDList}; do
  /usr/bin/curl -s "${url}/api/v2/mdm/commands" -H 'Content-Type: application/json' -H "Authorization: Bearer ${token}" \
--data "{
  \"clientData\": [
    {
      \"managementId\": \"${theManID}\"
    }
  ],
  \"commandData\": {
    \"commandType\": \"ENABLE_LOST_MODE\",
    \"lostModeMessage\": \"${lost_mode_message}\",
    \"lostModePhone\": \"${lost_mode_phone}\",
    \"lostModeFootnote\": \"${lost_mode_footnote}\"
  }
}"
  sleep 1
  case "${play_lost_mode_sound}" in
  true|TRUE|True)
    /usr/bin/curl -s "${url}/api/v2/mdm/commands" -H 'Content-Type: application/json' -H "Authorization: Bearer ${token}" \
  --data "{
    \"clientData\": [
      {
        \"managementId\": \"${theManID}\"
      }
    ],
    \"commandData\": {
      \"commandType\": \"PLAY_LOST_MODE_SOUND\"
    }
  }"
  ;;
  
  *)
    /bin/echo "Do nothing" >/dev/null 2>&1
    ;;
    
  esac
  sleep 1
done

# invalidate the token
/usr/bin/curl -s -X POST "${url}/api/v1/auth/invalidate-token" -H "Authorization: Bearer ${token}"
