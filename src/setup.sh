#!/bin/bash

# Run this script as: . ./setup.sh
# This sets up the HVSC path that some source files need for SIDs.

HVSC="$HOME/Music/HVSC69/"

if [ ! -d "$HVSC" ]; then
	echo "$HVSC: no such directory"
fi

cat <<EOF >local.inc
#importonce

.const HVSC = "$HVSC"
EOF

export HVSC
