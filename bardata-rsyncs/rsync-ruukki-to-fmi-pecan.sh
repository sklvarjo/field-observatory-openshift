
#!/bin/bash
rsync -rva -e ssh --size-only --no-perms --no-times --exclude-from="/home/nevalaio/rsync-exclude-list-ruukki.txt" /mnt/data/BARData/Ruukki nevalaio@fmi-pecan.fmi.fi:/data/BARData/
