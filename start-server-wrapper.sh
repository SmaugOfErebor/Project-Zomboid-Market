#!/bin/bash

# Start the command as a coprocess
coproc MYPROC { stdbuf -oL ./start-server.sh; }

# MYPROC[0] = stdout of program
# MYPROC[1] = stdin of program

# Monitor output
while read -r line <&"${MYPROC[0]}"; do
    echo "$line"
    
    # Check for the trigger text
    if [[ "$line" =~ \[PZ\ Market\]\ ([a-zA-Z0-9_]+)\ Balance:\ ([0-9]+) ]]; then
        playername="${BASH_REMATCH[1]}"
        balance="${BASH_REMATCH[2]}"
        echo "servermsg \"Player $playername Balance: $balance\"" >&"${MYPROC[1]}"
    fi
done