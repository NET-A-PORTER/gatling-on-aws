#!/bin/sh -e

LOG_DIR=$1

if [ "x$LOG_DIR" == x ] || [ ! -d "$LOG_DIR" ] ; then
    echo "This script takes as its argument a directory of ELB log dumps"
    exit 4
fi

# Print TSV header
echo "status\turl"

# Grab the PATH part of all successfully served URLs, ignoring differences in ports (e.g. 80 / 443)
for f in $LOG_DIR/* ; do
    awk '
        # Ignore invalid URLs
        $13 ~ "%_" { next }

        # Ignore differently invalid URLs..
        $13 ~ "\"" { next }

        {
             # Strip off scheme, domain & port
             sub("https?://[^/]+", "", $13)

             # print out statusCode & path, TAB separated
             printf "%s\t%s\n", $8, $13
        }' < $f
done
