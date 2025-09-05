
#!/bin/bash
rsync -rva -e ssh --size-only --no-perms --no-times --exclude-from="/home/nevalaio/rsync-exclude-list-virrat.txt" /mnt/data/BARData/Virrat nevalaio@fmi-pecan.fmi.fi:/data/BARData/
