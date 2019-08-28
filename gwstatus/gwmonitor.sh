#!/usr/bin/python

#########################################################################
##
##  This file is part of the TTN Gateway monitoring solution by RFSee.
##
##  The script is free software:
##  you can redistribute it and/or modify it under the terms of a Creative
##  Commons Attribution-NonCommercial 4.0 International License
##  (http://creativecommons.org/licenses/by-nc/4.0/) by
##  PE1MEW (http://rfsee.nl) E-mail: remko@rfsee.nl
##
##  The TTN gateway motioring script is distributed in the hope that
##  it will be useful, but WITHOUT ANY WARRANTY; without even the
##  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
##  PURPOSE.
##
########################################################################

##
## \file gwmonitor.sh
##
## \brief TTN Gateway montor script
## This script monitors TTN gateway using the API delivered by The Things Network.
## The script will send a message on Twitter and Slack using Webhooks when the
## Gateway is considered offline or down.
##
## \author Remko Welling (remko@rfsee.nl)
## \date 26-8-2019
##
## \todo Add functionality to do something sensible with up- and dowlink packet count 
##
## \note Please not that this script is work in progress! There is still a lot of
##       debugging commands in the script and unfinished code
##
## #Version history
##
## version |Date        |Comments
## -----------------------------------------------------------------
## 1.0     | 23-8-2019  | Initial version with Twitter and Slack posting
## 2.0     | 23-8-2019  | New version with optimisations. Change to new status URL
## 2.22    | 23-8-2019  | Rearrangement of software, added functions and documentation
## 2.23    | 23-8-2019  | Added uplink and downlink data handling
## 2.24    | 23-8-2019  | Added readable time to up message, Added 30 minute interval in status when gateway is down
## 2.25    | 24-8-2019  | Added inital processing of packet stats reported by TTN, added UNIX temestamp to registry data. 
## 2.26    | 25-8-2019  | Added use of command line arguments
## 2.27    | 25-8-2019  | Added configuration of timezone
## 2.28    | 26-8-2019  | Added test function. Invoked when CRONTAB_INTERVAL is set 0
## 2.29    | 28-8-2019  | Fixed: #1 "totalDownTime is incorrect when gateway comes back on line" added writing old down time at handling states.
##

VERSION_MAYOR = "2"   # shall be string!
VERSION_MINOR = "29"  # shall be string!

# import libraries
import sys                  # commanline arguments
import requests             # web requests end posts
import time
import datetime
from datetime import date
import calendar
import dateutil.parser as dp
import json
from twython import Twython # Twitter API


# import Slack credentials from file: slack_auth.py
from slack_auth import(
    webhook_url
    )

# Import twitter credentials from file twitter_auth.py
from twitter_auth import (
    consumer_key,
    consumer_secret,
    access_token,
    access_token_secret
)

# prepare Twitter API
twitter = Twython(
    consumer_key,
    consumer_secret,
    access_token,
    access_token_secret
)

## function definitions and structs

## Struct used by display_time() function.
intervals = (
    ('weeks', 604800),  # 60 * 60 * 24 * 7
    ('days', 86400),    # 60 * 60 * 24
    ('hours', 3600),    # 60 * 60
    ('minutes', 60),
    ('seconds', 1),
    )

## \brief Convert seconds in to Years, Weeks, Days, Minutes, and Seconds
## \param seconds
## \param granularity Resolution of result. 1 is Years, 5 is Years, Weeks, Days, Minutes, and Seconds
## \return string with Years, Weeks, Days, Minutes, and Seconds
def display_time(seconds, granularity=2):
    result = []

    for name, count in intervals:
        value = seconds // count
        if value:
            seconds -= value * count
            if value == 1:
                name = name.rstrip('s')
            result.append("{} {}".format(value, name))
    return ', '.join(result[:granularity])

registryData = {
    u"version": VERSION_MAYOR + VERSION_MINOR,
    u"time_stamp": 0,
    u"down": 0,
    u"down_time": 0,
    u"uplink": 0,
    u"downlink": 0
    }

## \brief write registry file
## \param fileName Name of file
## \pre read actual time and set it.
def write_registry_file():
    registryData['down'] = down
    registryData['down_time'] = newDownTime
    registryData['version'] = version
    registryData['uplink'] = uplinkPackets
    registryData['downlink'] = downlinkPackets
    registryData['time_stamp'] = currentTime
    with open(GATEWAY_ID+"_registry.json", "w") as write_file:
       json.dump(registryData, write_file)
    ## \todo Add error handling

## \brief send tweet
## \param tweetMessage message to be tweeted
## \pre set athentication credentials in file twitter_auth.py
def sendTweet(tweetMessage):
    timeToLastSeen=display_time(delta, 4)
    result = twitter.update_status(status=tweetMessage)

## \brief send message on Slack using webhook
## \param tweetMessage message to be posted
## \pre set athentication credentials in file slack_auth.py
def sendSlack(slackMessage):
    slack_data = {'text': slackMessage}
    response = requests.post(
        webhook_url, data=json.dumps(slack_data),
        headers={'Content-Type': 'application/json'}
    )
    if response.status_code != 200:
        raise ValueError(
        'Request to slack returned an error %s, the response is:\n%s'
        % (response.status_code, response.text)
        )
        sys.exit (1)


### Start of Python script

## Read configuration from commandline arguments
if len(sys.argv[1:]) != 2 :
    print "Usage: ./gwmonitor <gateway_name> <cron_interval_seconds>."
    sys.exit (1)

## EUI of the gateway to be monitored as specified in TTN Console
GATEWAY_ID = sys.argv[1]
## Interval in seconds at which the script is executed in crontab
CRONTAB_INTERVAL = int(sys.argv[2])

## Fixed configuration parameters of the script

## URL of gateway status at TTN
STATUS_URL = "http://noc.thethingsnetwork.org:8085/api/v2/gateways/"
## Timeout in seconds before the script will detect possible off-line of the gateway
KEEPALIVE_TIMEOUT_S = 120
## Set timezone with respect to UTC (in hours)
TIMEZONE = 1 

## get current UTC time in unix timestamp
UTCTime = datetime.datetime.utcnow()
currentTime = int(time.mktime(UTCTime.timetuple()))
newDownTime = currentTime
oldTime = currentTime

## initialze variables used
version = VERSION_MAYOR + VERSION_MINOR
down = 0
uplink = 0
downlink = 0
uplinkPackets = 0
downlinkPackets = 0
oldUplinkPackets = 0
oldDownlinkPackets = 0


## check for status file and open it else create it and prepare for usage
try:
    with open(GATEWAY_ID+"_registry.json", "r") as read_file:
        registryData = json.load(read_file)
#    print("Loaded registry data")
except IOError:
    write_registry_file()
#    print('Error reading configuration file')

#print(json.dumps(registryData, indent=4))

# save data for use

# Test is reggistry file is at the minimum level for compatibility purposes.
# When registry file is incompatible create new file and reset to default values.
version = registryData.get('version')
if ( version < VERSION_MAYOR + VERSION_MINOR ):
    version = VERSION_MAYOR + VERSION_MINOR
    down = 0               # set down count to default
    uplinkPackets = 0      # set uplink packet counter to 0
    downlinkPackets = 0    # set downlink packet counter to 0
    write_registry_file()  # write new registry file
else:
    down = registryData.get('down')                # read down counter
    oldUplinkPackets = registryData.get('uplink')     # read uplink packets
    oldDownlinkPackets = registryData.get('downlink') # read downlink packets
    oldTime = registryData.get('time_stamp') # read last time
    oldDownTime = registryData.get('down_time') # read time at which gateway went down

#print("Uplink from registry: "+'{:d}'.format(uplinkPackets))
#print("Downlink from registry: "+'{:d}'.format(downlinkPackets))

## get actual gateway status
jsonResp = requests.get(STATUS_URL+GATEWAY_ID)
#pprint.pprint(jsonResp.content)
if jsonResp.status_code != 200:
    # This means something went wrong.
    raise ApiError('GET gateways {}'.format(jsonResp.status_code))

# parse responce
jsonData = json.loads(jsonResp.content)
#print(json.dumps(jsonData, indent=4))

uplinkPackets = jsonData.get('rx_ok')
downlinkPackets = jsonData.get('tx_in')

#print("Uplink from registry: "+'{:d}'.format(oldUplinkPackets))
#print("Downlink from registry: "+'{:d}'.format(oldDownlinkPackets))
#print("Uplink from TTN: "+'{:d}'.format(uplinkPackets))
#print("Downlink from TTN: "+'{:d}'.format(downlinkPackets))

deltaUplinkPackets = uplinkPackets - oldUplinkPackets
deltaDownlinkPackets = downlinkPackets - oldDownlinkPackets

#print("Delta uplink: "+'{:d}'.format(deltaUplinkPackets))
#print("Delta downlink: "+'{:d}'.format(deltaDownlinkPackets))

deltaUplinkPacketsMinute = (uplinkPackets - oldUplinkPackets)
deltaDownlinkPacketsMinute = (downlinkPackets - oldDownlinkPackets)

deltaTime = (currentTime-oldTime)/60
#print(deltaTime)

# \todo prevent using 0 for average.
#print("Uplink average packets/minute: "+'{:d}'.format(deltaUplinkPacketsMinute/deltaTime))
#print("Downlink average packets/minute: "+'{:d}'.format(deltaDownlinkPacketsMinute/deltaTime))


# get last gateway activity time and convert to unix timestamp
lastSeen = jsonData.get('timestamp')
lastSeenParsed = dp.parse(lastSeen)
#pprint.pprint(lastSeen)
lastTime = int(lastSeenParsed.strftime('%s'))
#print(lastTime)

## calculate time difference and correct for time zone difference to UTC.
delta=currentTime-lastTime+(TIMEZONE*3600)
#print(delta)

totalDownTime = currentTime - oldDownTime

## Compose messages
timeToLastSeen = display_time(delta, 4)
downMessage = "Gateway \""+GATEWAY_ID+"\" seems down! Last message was "+timeToLastSeen+" ago. ["+VERSION_MAYOR+"."+VERSION_MINOR+"]"

readableLastTime = datetime.datetime.fromtimestamp(lastTime).strftime('%H:%M:%S %Y-%m-%d')
readableTotalDownTime = display_time(totalDownTime, 4)
upMessage = "Gateway \""+GATEWAY_ID+"\" is back in operation since "+readableLastTime+". Total down time was "+readableTotalDownTime+". ["+VERSION_MAYOR+"."+VERSION_MINOR+"]"

if (CRONTAB_INTERVAL == 0):
    # Test message
    testMessage = "Gateway \""+GATEWAY_ID+"\" status: Last activity: "+readableLastTime+". Total received packets: "+str(uplinkPackets)+", Total transmitted packets: "+str(downlinkPackets)+". Testing script version: "+VERSION_MAYOR+"."+VERSION_MINOR+"."
    sendSlack(testMessage)
    sendTweet(testMessage)
else:
    # Process states
    if ( delta > KEEPALIVE_TIMEOUT_S ):
        down += 1
        newDownTime = oldDownTime # Set down-time to down-time read from file to preserve it
        write_registry_file()
        if ( down == 1 ):
            newDownTime = currentTime # Set down-time to current time at first detection of down
            write_registry_file()
            sendSlack(downMessage)
            sendTweet(downMessage)
        if ( down > 1 ):
            if ((down * CRONTAB_INTERVAL) % 1800 == 0):
                sendSlack(downMessage)
    else:
        if ( down > 0 ):
            down = 0
            write_registry_file()
            sendSlack(upMessage)
            sendTweet(upMessage)

        write_registry_file()
