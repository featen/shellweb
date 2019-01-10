#!/bin/bash

respond() {
    echo "HTTP/1.1 200 OK"
    echo "Connection: close"
    echo "Content-Type: $contentType; charset=utf-8"
    echo "Content-Length: ${#body}"
    echo "Host: $host"
    echo "Date: $(TZ=UTC; date '+%a, %d %b %Y %T GMT')"
    echo -e "\n$body"
}

read -r request
read method path protocol < <(echo $request)
if [ "$method" != 'GET' ]; then
    echo 'HTTP/1.1 405 Method Not Allowed'
    echo -e "\n405 Method Not Allowed"
    exit 0
fi
path="${path%%\?*}"

case "$path" in
    *.html) contentType='text/html' ;;
    *.jpg|*.jpeg) contentType='image/jpeg' ;;
    *.png) contentType='image/png' ;;
    *.ico) contentType='image/x-icon' ;;
    *.js) contentType='application/x-javascript' ;;
    *) contentType='application/octet-stream';;
esac

while :
do
    read -r header
    [[ "${header[0]}" == $'\r' || "${header[0]}" == $'\n' ]] && break
    case "$header" in
        Host:*) read ok host < <(echo $header) ;;
        *)  : ;;
    esac
done

case "$host" in 
    *) rootDir='/var/share/html/default' ;;
esac

filePath="${rootDir}/${path}"
if [[ -f "$filePath" ]]
then
    body=$(<$filePath)
else
    echo 'HTTP/1.1 404 Not Found'
    echo -e "\n404 Not Found"
    exit 0
fi

respond 
exit 0

