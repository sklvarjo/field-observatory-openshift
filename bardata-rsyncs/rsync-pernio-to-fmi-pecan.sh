
#!/bin/bash
rsync -rva -e ssh --size-only --no-perms --no-times --exclude-from="/home/nevalaio/rsync-exclude-list-pernio.txt" /mnt/data/BARData/Pernio nevalaio@fmi-pecan.fmi.fi:/data/BARData/
