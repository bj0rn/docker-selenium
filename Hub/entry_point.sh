#!/bin/bash

export SEL_HOME=/opt/selenium

# Setup nss_wrapper so the random user OpenShift will run this container
# has an entry in /etc/passwd.
# This is needed for 'git' and other tools to work properly.
#
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < ${SEL_HOME}/passwd.template > ${SEL_HOME}/passwd
export LD_PRELOAD=libnss_wrapper.so
export NSS_WRAPPER_PASSWD=${SEL_HOME}/passwd
export NSS_WRAPPER_GROUP=/etc/group

ROOT=/opt/selenium
CONF=$ROOT/config.json

/opt/bin/generate_config >$CONF

echo "starting selenium hub with configuration:"
cat $CONF

if [ ! -z "$SE_OPTS" ]; then
  echo "appending selenium options: ${SE_OPTS}"
fi

function shutdown {
    echo "shutting down hub.."
    kill -s SIGTERM $NODE_PID
    wait $NODE_PID
    echo "shutdown complete"
}

java ${JAVA_OPTS} -jar /opt/selenium/selenium-server-standalone.jar \
  -role hub \
  -hubConfig $CONF \
  ${SE_OPTS} &
NODE_PID=$!

trap shutdown SIGTERM SIGINT
wait $NODE_PID
