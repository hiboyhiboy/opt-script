ebtables -t broute -A BROUTING -i ra0 -j ACCEPT
ebtables -t broute -A BROUTING -i eth2.1 -j ACCEPT
ebtables -t broute -A BROUTING -p ! IPv6 -j DROP
ebtables -A FORWARD -o eth2.2 -p ! IPv6 -j DROP