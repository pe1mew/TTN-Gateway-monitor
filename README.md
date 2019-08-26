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

I found the solution for Twitter in <a href="https://projects.raspberrypi.org/en/projects/getting-started-with-the-twitter-api">"Getting started with the Twitter API"</a> and for Slack at <a href="https://api.slack.com/incoming-webhooks">"Send data into Slack in real-time"</a>

.

