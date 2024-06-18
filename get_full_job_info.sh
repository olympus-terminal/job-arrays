#!/bin/bash

while read l ; do for i in {1..8}; do echo ' '; done; echo "$l"; get_node_info_from_job.sh $l; done < j >> currentjobs.txt
