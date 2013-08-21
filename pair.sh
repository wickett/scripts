#!/bin/sh
# ************************** CREDITS ****************************
# The original version of this script is found from @marksim at https://gist.github.com/marksim/5785406

# *************************** SETUP ****************************
# Find the LAN IP, the External IP, and the pair users's group
INTERFACE=$(netstat -rn -f inet | grep default | awk '{print $6}')
LAN_IP=$(ipconfig getifaddr $INTERFACE)
EXTERNAL_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
#GROUP=$(id -g pair)
GROUP='everyone'
ROUTER='192.168.11.1'

if [[ $1 = 'start' ]];
  then 
  # Download the public keys to the pair user
  sudo bash -c "curl https://github.com/$2.keys 2>/dev/null >> ~pair/.ssh/authorized_keys"
  sudo chown pair:$GROUP /Users/pair/.ssh/authorized_keys
 
  # Punch a hole in the firewall
  ssh root@$ROUTER "iptables -t nat -I PREROUTING -p tcp --dport 2222 -j DNAT --to $LAN_IP:22 && iptables -I FORWARD -p tcp -d $LAN_IP --dport 22 -j ACCEPT" 
  # Copy the ssh command to the clipboard - OS X specific
  echo "give this to the pairer > ssh pair@$EXTERNAL_IP -p2222"
  echo "tell them to run this > tmux -S /tmp/pairing attach -t pairing"
  sleep 5
  
  # ************************** PAIRNG ****************************
  tmux -S /tmp/pairing new -ds pairing && chgrp $GROUP /tmp/pairing && tmux -S /tmp/pairing attach -t pairing

elif [[ $1 = 'stop' ]];
  then 
  # ************************** CLEANUP ***************************
  # Cleanup keys
  sudo rm -f /Users/pair/.ssh/authorized_keys
  # remove hole in the firewall
  ssh root@$ROUTER "iptables -t nat -D PREROUTING -p tcp --dport 2222 -j DNAT --to $LAN_IP:22 && iptables -D FORWARD -p tcp -d $LAN_IP --dport 22 -j ACCEPT" 

  # boot user off machine
  sudo kill -9 `who -u | grep pair | rev | cut -f1 -d" " | rev`

else
  echo "Usage: pair.sh [start|stop] [github_id]"
fi

exit

