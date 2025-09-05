
#!/bin/bash
rsync -rva -e ssh --size-only --no-perms --no-times --exclude-from="/home/nevalaio/rsync-exclude-list-hahkiala.txt" /mnt/data/BARData/Hahkiala nevalaio@fmi-pecan.fmi.fi:/data/BARData/
