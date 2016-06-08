#!/bin/sh

# Many things aren't perfect. Some of those are daemons we need to run 24/7
# despite being written not well enough to not freeze from time to time.
# For those, I wrote this also very much not perfect script. But it should do
# it's job restarting a daemon (run by daemontools) and then checking,
# whether the targeted process actually has a new pid. If not, it may already
# have frozen (ignoring the small chance of hitting the same pid again).
# If the pid didn't change after a graceful restart by daemnontools, we'll just
# kill -9 it. If the pid is still the same after that, we assume something
# went just too wrong to do any more with this script and instead go tell
# someone with a brain.
# I suggest running this as a cron job.
#
# - Alex H.

set -eu

phrase="$1"
service_dir="$HOME/service"
seconds='2'	# Seconds we will wait for the process to be restarted.

function getpid {
	pid="$(ps ux | grep -v 'supervise' | grep -e '?' \
		| grep -e "${phrase}" | grep -v 'grep' | awk '{print $2}')"
	case ${n} in
		0)	pid0="${pid}"
			;;
		1)	pid1="${pid}"
			;;
		2)	pid2="${pid}"
			;;
	esac
	n="$(( ${n} + 1 ))"
}

function restart_daemon {
	svc -du ${service_dir}/${phrase}
}

n="0"

getpid
restart_daemon
sleep ${seconds}
getpid

if [[ ${pid0} -eq ${pid1} ]]; then
	echo "Restarting ${phrase} likely not successfull."
	echo "Killing process ${pid0} forcefully."
	kill -9 ${pid0}
	sleep ${seconds}
	getpid
	if [[ ${pid0} -eq ${pid2} ]]; then
		echo "Still no luck. Check yo'self."
		exit 2
	else
		echo "All good now."
		exit 1
	fi
else
	echo "Restarted ${phrase} cleanly."
fi
exit 0
