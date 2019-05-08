#!/bin/bash

ICINGA_HOSTNAME="<YOUR_ICINGAWEB2_HOSTNAME>"
ROCKETCHAT_WEBHOOK_URL="<YOUR_ROCKETCHAT_WEBHOOK_INTEGRATION_URL>"

## Main
while getopts 4:6:b:c:d:e:f:hi:l:n:o:r:s:t:u:v: opt
do
  case "$opt" in
    4) HOSTADDRESS=$OPTARG ;;
    6) HOSTADDRESS6=$OPTARG ;;
    b) NOTIFICATIONAUTHORNAME=$OPTARG ;;
    c) NOTIFICATIONCOMMENT=$OPTARG ;;
    d) LONGDATETIME=$OPTARG ;; # required
    e) SERVICENAME=$OPTARG ;; # required
    h) Usage ;;
    i) ICINGAWEB2URL=$OPTARG ;;
    l) HOSTNAME=$OPTARG ;; # required
    n) HOSTDISPLAYNAME=$OPTARG ;; # required
    o) SERVICEOUTPUT=$OPTARG ;; # required
    r) USEREMAIL=$OPTARG ;; # required
    s) SERVICESTATE=$OPTARG ;; # required
    t) NOTIFICATIONTYPE=$OPTARG ;; # required
    u) SERVICEDISPLAYNAME=$OPTARG ;; # required
    v) VERBOSE=$OPTARG ;;
  esac
done

#Set the message icon based on ICINGA Host state
if [ "$SERVICESTATE" = "CRITICAL" ]
then
    COLOR="danger"
elif [ "$SERVICESTATE" = "WARNING" ]
then
    COLOR="warning"
elif [ "$SERVICESTATE" = "OK" ]
then
    COLOR="good"
elif [ "$SERVICESTATE" = "UNKNOWN" ]
then
    COLOR="#800080"
else
    COLOR=""
fi

echo $SERVICEOUTPUT >> /tmp/chat
SERVICEOUTPUT=$(echo "$SERVICEOUTPUT"|tr '\n' ' - '|tr '\t' ' '|tr '"' "'")
echo $SERVICEOUTPUT >> /tmp/chat

#Send message to Slack
read -d '' PAYLOAD << EOF
{
  "text": "${SERVICENAME}: ${HOSTDISPLAYNAME} - ${SERVICEDISPLAYNAME}",
  "attachments": [
    {
      "collapsed": false,
      "color": "${COLOR}",
      "fields": [
        {
          "short": true,
          "title": "Service output",
          "value": "${SERVICEOUTPUT}"
        },
        {
          "short": true,
          "title": "Host",
	  "value": "[${HOSTDISPLAYNAME}](${ICINGA_HOSTNAME}/monitoring/host/services?host=${HOSTNAME})"
        },
        {
          "short": true,
          "title": "State",
          "value": "${SERVICESTATE}"
        }
      ],
      "title": "${SERVICENAME}",
      "text": "${SERVICESTATE}"
    }
  ]
}
EOF

curl --connect-timeout 30 --max-time 60 -s -S -X POST -H 'Content-type: application/json' --data "${PAYLOAD}" "${ROCKETCHAT_WEBHOOK_URL}"