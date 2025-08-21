#!/bin/sh
# PATH=$PATH:/volume1/@appstore/Node.js_v20/usr/local/lib/node_modules/forever/bin

# Based on https://github.com/StephanThierry/nodejs4synologynas
# Used to run the bot in the SynologyNAS
# Also review https://stackoverflow.com/questions/13385029/automatically-start-forever-node-on-system-restart
start() {
       forever start --env-file .env.production --workingDir /volume1/repos/wmgt/bots --sourceDir /volume1/repos/wmgt/bots/src -l /volume1/repos/wmgt/bots/logs/log.txt -a -o /volume1/repos/wmgt/bots/logs/output.txt .
}

stop() {
        killall -9 node
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  *)
    echo "Usage: $0 {start|stop}"
esac