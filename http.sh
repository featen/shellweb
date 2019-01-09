#!/bin/bash

LOG_DIR='/var/log/'
WWW_DIR='/usr/share/shweb/html'
ERROR_DIR='/usr/share/shweb/error'

ERR_XCD=86
ERR_NOTROOT=87


buildRespBody() {
    echo "<html><head><link rel='shortcut icon' type='image/x-icon' href='/favicon.ico'></head><body style='font-family: monospace; font-size: 32px;'><p>Hello Shweb</p></body></html>"
}

# respond
# params:
#   $1 - content-type (String)
#   $2 - body         (String)
respond() {
    echo "HTTP/1.1 200 OK"
    echo "Connection: close"
    echo "Content-Type: $1; charset=utf-8"
    echo "Content-Length: ${#2}"
    echo 'Link: </favicon.ico>; rel="icon"'
    echo "Host: featen.com"
    echo "Date: $(TZ=UTC; date '+%a, %d %b %Y %T GMT')"
    echo -e "\n$2"
}

500_error() {
    cat ${ERROR_DIR}/500 >&2
}

permRedirect() {
    echo 'HTTP/1.1 301 Moved Permanently'
    echo 'Location: http://featen.com/'
}

gotoDir() {
    cd $WWW_DIR || {
        500_error
            exit $ERR_XCD;
        }
}

read -r request

while :
do
    read -r header
    [ "$header" == $'\r' ] && break
done


# parse url & path
url="${request#GET }"
url="${url% HTTP/*}"
path="${url%%\?*}"
query="${url#*\?}"
if [[ "$path" == "$query" ]]; then
    query=''
fi

# parse it all
altResp=false
if [[ "$path" == '/index.html' || "$query" == 'type=html' ]]; then
    type='html'
    contentType='text/html'
elif [[ "$path" == '/favicon' || "$path" == '/favicon.ico' ]]; then 
    altResp=true
    echo 'HTTP/1.1 200 OK'
    echo -e "Content-Type: image/x-icon; charset=binary\n"
    cat '/root/shweb/beeroclock/favicon.ico'
    exit 0
elif [[ "${#query}" -gt 9 ]]; then # Unsupported Content-Type
    altResp=true
    echo 'HTTP/1.1 415 Unsupported Media Type'
    echo -e "\n415 Unsupported Media Type"
    exit 0
else # unknown route
    altResp=true
    permRedirect
    exit 0
fi

# if no alternative response, respond
if [[ "$altResp" == false ]]; then
    body="$(buildRespBody)"
    respond "$contentType" "$body"
    exit 0
fi
