
#!/bin/bash
rsync -rva -e ssh --size-only --no-perms --no-times --exclude-from="/home/nevalaio/rsync-exclude-list-lappila.txt" /mnt/data/BARData/Lappila nevalaio@fmi-pecan.fmi.fi:/data/BARData/
