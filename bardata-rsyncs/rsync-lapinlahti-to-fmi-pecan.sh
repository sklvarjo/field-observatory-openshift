
#!/bin/bash
rsync -rva -e ssh --size-only --no-perms --no-times --exclude-from="/home/nevalaio/rsync-exclude-list-lapinlahti.txt" /mnt/data/BARData/Lapinlahti nevalaio@fmi-pecan.fmi.fi:/data/BARData/
