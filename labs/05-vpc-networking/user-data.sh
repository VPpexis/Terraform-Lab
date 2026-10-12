#!/bin/sh

mkdir -p /var/www/
echo "<h1>Hello World</h1>" > /var/www/index.html
apk add --no-cache busybox-extras
httpd -p 8080 -h /var/www