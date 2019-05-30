#!/bin/sh

while true; do
  curl -s http://${HOST}${URI} > /dev/null
done
