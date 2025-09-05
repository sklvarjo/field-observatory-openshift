
#!/bin/bash
rsync -rva -e ssh --size-only --no-perms --no-times --exclude-from="/home/nevalaio/rsync-exclude-list-sodankyla.txt" /mnt/data/ICOS/FI-Sod nevalaio@fmi-pecan.fmi.fi:/data/ICOS/
