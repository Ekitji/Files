# Files
Files


## LOLDriverScanner All
https://www.loldrivers.io/api/drivers.json
Download the LOLDriverScanner_ALL script and download the drivers.json file (link above, sorry no webrequest included, dont like pwsh talking to internet =] )
Put the drivers.json in LOLDriverScanners root folder and run the script.
This one is more aggressive and will search in whole C: for sys-files. It checks MD5,SHA1,SHA256, Authenticode (SHA256) against the loldrivers json file.

The results will be in console or GridView (excel look-a-like)

## LOLDriverScanner
https://www.loldrivers.io/api/drivers.json
Light variant which is only checking SHA256 AND Authenticode but some loldrivers from the json file dont have these entries and you will likely miss them if
they exist in your system.

Download the LOLDriverScanner script and download the drivers.json file (link above, sorry no webrequest included, dont like pwsh talking to internet =] )
Correct the path "$loldriversFilePath" in the powershell script to the location of your drivers.json or just simply put the drivers.json in same root folder as LOLDriverscanner script.

Run the script and check the results in console or GridView (excel look-a-like)

Special thanks to:
Oddvar Moe @ Twitter, http://oddvar.moe
for the idea.

### Webrequest support and additional feature with path/file extension changes
@MHaggis at
https://github.com/MHaggis/notes/blob/master/utilities/scan-drivers.ps1


### Living Off The Land Drivers
Living Off The Land Drivers is a curated list of Windows drivers used by adversaries to bypass security controls and carry out attacks. The project helps security professionals stay informed and mitigate potential threats.
https://www.loldrivers.io/api/drivers.json



