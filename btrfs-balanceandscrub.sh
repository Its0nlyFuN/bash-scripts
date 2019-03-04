#!/bin/bash

echo "--:> starting balance and scrub of filesystem /"
#btrfs balance start -musage=0 -v /
btrfs balance start -musage=50 -v /
#btrfs balance start -dusage=0 -v /
btrfs balance start -dusage=50 -v /
sleep 2
btrfs scrub start -Bd -c 2 -n 3 /
sleep 2
echo "--:> starting balance and scrub of filesystem /home"
#btrfs balance start -musage=0 -v /home
btrfs balance start -musage=50 -v /home
#btrfs balance start -dusage=0 -v /home
btrfs balance start -dusage=50 -v /home
sleep 2
btrfs scrub start -Bd -c 2 -n 3 /home
sleep 2
echo "--:> done!"
exit 0
