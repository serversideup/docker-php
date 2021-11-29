#!/bin/bash
echo "4" > /tmp/test.txt
[ $RESULT -ne 0 ] && exit 1
exit 0