#!/bin/bash
rsync -rva -e ssh --size-only --no-perms --no-times --exclude-from="/home/nevalaio/rsync-exclude-list-qvidja.txt" /mnt/data/BARData/Qvidja nevalaio@fmi-pecan.fmi.fi:/data/BARData/
