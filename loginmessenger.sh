#!/bin/sh

######
#
# loginmessenger.sh - User login and logout messenger script
#
# This script (for Mac OS X) sends a message to an API when a user has logged in or 
# logged out of the computer. 
#
######

# URL where the login/logout messages will be posted
API_URL="https://servername/idcheck/api/checkin"
API_USERNAME="username"
API_PASSWORD="password"

# Get this computer's name
computer_name=$(/usr/sbin/scutil --get ComputerName)

# Capture the username of currently logged in persion.
current_user=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Default to 200 success http response for API login and logout calls
http_response_login="200"
http_response_logout="200"

# Send LOGIN message to API.
http_response_login=$(curl -s -o /dev/null -w "%{http_code}" -X POST -u "$API_USERNAME:$API_PASSWORD" "$API_URL?servicecode=LOGIN&studentid=$current_user&checkedby=$computer_name")

if [ "$http_response_login" -ne "200" ]; then
    echo "Sending LOGIN API message failed with status: $http_response_login"
fi

# make sure we don't send the logout more than once, which can sometimes happen
sentlogout=false

# Create trap for interrupt and to send LOGOUT message when the process is sent a message to terminate. 
# Might be called twice in some situations.
on_complete() {
    if [ $sentlogout = false ]; then
        # Send LOGOUT message to API.
        http_response_logout=$(curl -s -o /dev/null -w "%{http_code}" -X POST -u "$API_USERNAME:$API_PASSWORD" "$API_URL?servicecode=LOGOUT&studentid=$current_user&checkedby=$computer_name")
        sentlogout=true
    fi
    
    # Exit depends on HTTP status code.
    if [ "$http_response_logout" == "200" ]; then
        exit 0
    else
        echo "Sending LOGOUT API message failed with status: $http_response_logout"
        exit 1
    fi
}
 
trap 'on_complete 2> /dev/null' SIGTERM SIGINT SIGHUP EXIT

# keep process alive for 1 day
sleep 86400 & wait

