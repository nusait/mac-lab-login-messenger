# mac-lab-login-messenger
On the Mac, this is used to send a message to an API every time someone logs in or logs out of the computer.

## Details and Installation
This is very basic, with much of the functionality handled by the Mac's launchd. Here is a description of the files and what they do, and the permissions they should have:

- edu.northwestern.dosa.loginmessenger.plist - This plist should be put into /Library/LaunchAgents. This will run the shell script to run every time someone logs into the computer. It will not try to restart the shell script if it crashes.
*This file needs to be chown root:wheel and chmod 644* 
- login-messenger.sh - This shell script should be put into /Library/Scripts . It gathers the currently logged-in user name and the computer name, and sends them to the API with a "LOGIN" message. It then stays open and waits. When the script is sent a "terminate" signal (such as when the user logs out or the computer restarts), the script then sends the "LOGOUT" message, again with the username and computer name to the API.
*This script needs to be chown root:wheel and chmod 755*

It is important to have proper permissions set on these files, or else they will not run.

## How I'm capturing the username
This was not straightforward. This resource helped me: 
https://scriptingosx.com/2019/09/get-current-user-in-shell-scripts-on-macos/

At first I tried capturing the username using the "last" command, which seemed to work well:

`current_user=$(last -t console | grep "still logged in" | awk '{print $1}')`

However, according to the link above, it apears that using the scutil command will be more accurate:

`current_user=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )`

If this ever stops working, I'm willing to bet that the "last" command might have more longevity since it is a core UNIX command.

## Additional resources
These are some links that I found helpful when putting together this script. 

- https://stackoverflow.com/questions/72134147/how-to-programmatically-start-an-application-at-user-login
- https://apple.stackexchange.com/questions/123631/why-does-a-shell-script-trapping-sigterm-work-when-run-manually-but-not-when-ru
- https://www.launchd.info/
- https://stackoverflow.com/questions/69388515/launch-job-unable-to-execute-bash-script-receiving-abnormal-code-126

One other thing to note: An earlier version of the script was storing the username of the logged in user into a file and was comparing it every couple of minutes (script was run by cron). There were several issues with this; cron would not reliably run after reboot (and before anyone logged in). And on the Mac, disk access requires special permissions be set in the System Settings. So I opted to go with the launchd solution instead.

