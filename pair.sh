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
  echo "Please provide the password for sudo"
  sudo bash -c "curl https://github.com/$2.keys 2>/dev/null >> ~pair/.ssh/authorized_keys"
  sudo sed -i -e 's/^/command\=\"\/usr\/local\/bin\/tmux\ \-S\ \/tmp\/pairing\ attach\ \-t\ pairing\"\,no\-port\-forwarding\,no\-X11\-forwarding\ /' ~pair/.ssh/authorized_keys
  sudo chown pair:$GROUP /Users/pair/.ssh/authorized_keys
 
  # Punch a hole in the firewall
  echo "Please provide the password for the router"
  ssh root@$ROUTER "iptables -t nat -I PREROUTING -p tcp --dport 2222 -j DNAT --to $LAN_IP:22 && iptables -I FORWARD -p tcp -d $LAN_IP --dport 22 -j ACCEPT" 
  # Copy the ssh command to the clipboard - OS X specific
  echo "give this to the pairer > ssh pair@$EXTERNAL_IP -p2222"
  sleep 8
  
  # ************************** PAIRNG ****************************
  tmux -S /tmp/pairing new -ds pairing && chgrp $GROUP /tmp/pairing && tmux -S /tmp/pairing attach -t pairing

  # ************************** CLEANUP ***************************
  # Cleanup keys
  echo "deleting the pairee keys, might need sudo password"
  sudo rm -f /Users/pair/.ssh/authorized_keys

  # boot user off machine 
  sudo kill -9 `who -u | grep pair | tr -d ' ' | cut -f2`

  # remove hole in the firewall
  echo "Please provide the password for the router"
  ssh root@$ROUTER "iptables -t nat -D PREROUTING -p tcp --dport 2222 -j DNAT --to $LAN_IP:22 && iptables -D FORWARD -p tcp -d $LAN_IP --dport 22 -j ACCEPT" 

  # one last chance to make sure the pair user didnt get back on before firewall rules went into affect
  sudo kill -9 `who -u | grep pair | tr -d ' ' | cut -f2`
  echo "Killing pairing session now, CTRL-c to save the session"
  echo "..."
  sleep 10
  tmux -S /tmp/pairing kill-session -t pairing

else
  echo "Usage: pair.sh [start] [github_id]"
fi

exit
