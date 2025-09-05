#!/bin/bash
rsync -rva -e ssh --size-only --no-perms --no-times --exclude-from="/home/nevalaio/rsync-exclude-list-haltiala.txt" /mnt/data/BARData/Haltiala nevalaio@fmi-pecan.fmi.fi:/data/BARData/
