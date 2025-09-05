
#!/bin/bash
rsync -rva -e ssh --size-only --no-perms --no-times --exclude-from="/home/nevalaio/rsync-exclude-list-kauhajoki.txt" /mnt/data/BARData/Kauhajoki nevalaio@fmi-pecan.fmi.fi:/data/BARData/
