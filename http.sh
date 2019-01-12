#!/bin/bash

RespondHtml ()
{
    echo "HTTP/1.1 200 OK"
    echo "Connection: close"
    echo "Content-Type: $content_type; charset=utf-8"
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
    *.html) content_type='text/html' ;;
    *.md) content_type='text/html'; type=markdown ;;
    *.jpg|*.jpeg) content_type='image/jpeg'; type=bin ;;
    *.png) content_type='image/png'; type=bin ;;
    *.ico) content_type='image/x-icon'; type=bin ;;
    *.js) content_type='application/x-javascript' ;;
    *.css) content_type='text/css' ;;
    *) content_type='application/octet-stream'; type=bin ;;
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
    *) root_dir="/home/jianjun/code/shellweb/html" ;;
esac

file_path="${root_dir}/${path}"
file_header="${root_dir}/header.html"
file_footer="${root_dir}/footer.html"

if [[ -f "$file_path" ]]
then
    if [[ "$type" == "bin" ]]; then 
        echo 'HTTP/1.1 200 OK'
        echo -e "Content-Type: $content_type; charset=binary\n"
        cat "$file_path"
        exit 0
    elif [[ "$type" == "markdown" ]]
    then
        mk_body=$(markdown $file_path)
        page_header=$(<$file_header)
        page_footer=$(<$file_footer)
        body=${page_header}${mk_body}${page_footer}
        RespondHtml
    else
        body=$(<$file_path)
        RespondHtml
        exit 0
    fi
else
    echo 'HTTP/1.1 404 Not Found'
    echo -e "\n404 Not Found"
    exit 0
fi

exit 0

