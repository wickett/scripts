#!/bin/bash 
# Taken from http://leonid.shevtsov.me/en/an-easy-way-to-use-tor-on-os-x
# need to do a brew install tor for this to work (don't install as daemon as brew recommends)

# sets up the socks proxy 
INTERFACE=Wi-Fi 
networksetup -setsocksfirewallproxy $INTERFACE 127.0.0.1 9050 off 
networksetup -setsocksfirewallproxystate $INTERFACE on 

#runs tor
tor  

#once you do a CTRL-C to stop tor, it turns the system-wide proxy setting off
networksetup -setsocksfirewallproxystate $INTERFACE off


