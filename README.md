# TTN-Gateway-monitor
A script that monitors a TTN gateway and sends status and updates to Twitter and Slack

## Disclaimer
The PE1MEW TTN Gateway monitoring script is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; Without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
## License
The PE1MEW TTN Gateway monitoring script is free software: You can redistribute it and/or modify it under the terms of a Creative Commons Attribution-NonCommercial 4.0 International License (http://creativecommons.org/licenses/by-nc/4.0/) by PE1MEW (http://pe1mew.nl) E-mail: pe1mew@pe1mew.nl.

<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a>.
# Introduction
With the expansion of The Things Network (TTN) the number of gateways is rapidly increasing. Together with these new gateways the need for a adequate monitoring is more urgent than ever. Information a gateway owner would like to have is if the gateway is on-line or not and performance figures. This information should be made available to the gateway owner and to the users as TTN is a public network. This solution aims to do just that: Present status information and events with respect to a TTN Gateway on Twitter and Slack.

With TTN V2-stack there is no solution for real-time monitoring. This might change in the future when V3-stack is put in operation but for now the TTN-Gateway-monitor script is using the information that the TTN V2-stack is providing to create a "real-time" monitoring system of TTN Gateways.

This script is inspired on the article <a href="https://www.disk91.com/2019/technology/lora/alarm-your-thethingsnetwork-gateway/">"Alarm your TheThingsNetwork gateway"</a> of Paul. The practical implementation using IFTT did not work for me as I do not like the idea of cluttering my Email with event messages. So I searched for alternative ways to get information published. 

I found the solution for Twitter in <a href="https://projects.raspberrypi.org/en/projects/getting-started-with-the-twitter-api">"Getting started with the Twitter API"</a> and for Slack at <a href="https://api.slack.com/incoming-webhooks">"Send data into Slack in real-time"</a> .
# Functionality
The script is run at regular intervals (5 minutes by default) where it requests the status of a gateway from the V2-stack of TTN. This actual status information is than evaluated in combination with (locally stored) historical status information. As a result of the evaluation the script determines if the gateway is "up" or "down".

A gateway is assumed to be "down" or "off-line" when the gateway is not "heard" for a period longer than 120 seconds by the V2-stack.

- When the observed gateway is found to be "up" and the previous state ws not down no message is sent.
- When the observed gateway is found to be "down" a message is sent on Twitter and Slack that states for how long the gateway is down. This message is repeated every 30 minutes on Slack (Not Twitter) as a reminder.
- When the observed gateway is found to be "up" after being down, a message is sent on Twitter an Slack that states when the gateway has come back on-line and for how long the gateway was off-line.
# Implementation
The TTN V2-stack is offering gateway status in JSON-format over the link: "http://noc.thethingsnetwork.org:8085/api/v2/gateways/<gateway_id>". The JSON struct delivered is presented below:
```
{
    "timestamp": "2019-08-22T08:23:44.121907589Z",
    "authenticated": true,
    "uplink": "13169328",
    "downlink": "78539",
    "location": {
        "latitude": 52.215855,
        "longitude": 5.963744,
        "altitude": 45
    },
    "frequency_plan": "EU_863_870",
    "platform": "IMST + Rpi",
    "gps": {
        "latitude": 52.215855,
        "longitude": 5.963744,
        "altitude": 45
    },
    "time": "1566462224121907589",
    "rx_ok": 13169328,
    "tx_in": 78539
}
```
From this struct the field "time", "rx_ok" and "tx_in" are being used.
- "time", is the epoch time (UTC!) in seconds at which the last message was received from the gateway by the V2-stack
- "rx_ok", is the total number of uplink packets received from the gateway at the time stated in "time"
- "tx_in", is the total number of downlink packets transmitted to the gateway at the time stated in "time"

The script is performing the following actions:
1. Initialisation:
   - Read credentials for Twitter API
   - Read url for Slack webhook
   - Read history data from previous execution of script
     - When file does not exist (at first use) create an new file with default values
     - Verify format of history file; when not OK update history file

![File handling](images/FlowChart_FileHandling.png "Handling of history data in script")

2. Generate intermediate results 
3. Retrieve last information from TTN
4. Analyse information and send messages to Twitter and Slack.

![Functional description](images/FlowChart_Functional.png "Functional description of script")

## Periodic execution
Periodic exectution of the script is implemented usig crontab that is available on any linux host OS. The crontab is configured to execute the script at an interval of 5 minutes. 

To allow multiple gateways to be monitored using a single script arguments are mandatory to specifiy the gateway-ID and teh interval at which the scipt is called form crontab. The syntax of the monitor script is:
```
./gwmonitor <gateway_name> <cron_interval_seconds>
```
# Installation
## Prepare the Linux host OS
Make sure the following programs are installed:
- github
- python
## Install on Linux host OS
_Preferrably start in the home directory of the user that will execute crontab._ 
Download the repository of the gateway monitor script:
```
git clone https://github.com/pe1mew/TTN-Gateway-monitor.git
```
copy the directory "gwstatus" to the location where crontab will execute it from: 
```
cp ~/TTN-Gateway-monitor/gwstatus/* ~/gwstatus/
```
Go to the directory where the script is located: 
```
cd ~/gwstatus/
```
Make the script executable:
```
chmod +x gwmonitor.sh 
```
Install mandatory python libraries: requests, dateutils, Twython
```
pip install requests
pip install dateutils
pip install Twython
```
Your scripts are now setup to be executed.

# Configuration

## Prerequisites
Before we run the script we have to setup access to Twitter and Slack and collect information from TTN about the gateway we will be monitoring. Keep track of all te information in a small ASCII logbook on, for example, notepad++. We than can simply copy all information to where we need it.
### Gateway-ID
The gateway-ID is obtained trough Console at TTN. 
![TTN_Console_GW-ID](images/TTNConsoleGWID.png "TTN Console Gateway-IDs")














# Modifications(hacks)
In the highly likely situation where you want to tailor the script to your owen needs I provide some hints:
1. 
