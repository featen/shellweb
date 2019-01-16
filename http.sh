#!/bin/bash

LANG=C
LC_ALL=C

Respond() {
    echo -e "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: $content_type; charset=utf-8\r\nContent-Length: ${#body}\r\nHost: $host"
    echo -e "Date: $(TZ=UTC; date '+%a, %d %b %Y %T GMT')\r\n"
    echo "$body"
    exit 0
}

Error404 () {
    echo -e "HTTP/1.1 404 Not Found\r\n404 Not Found"
    exit 0
}

Error405 () {
    echo -e "HTTP/1.1 405 Method Not Allowed\r\n405 Method Not Allowed"
    exit 0
}

main() {
    read -r request
    read method path protocol < <(echo $request)
    [ "$method" != 'GET' ] && Error405
    path="${path%%\?*}"
    [[ "${path}" == *(/)?(index.html) ]] && path="index.html"

    while :
    do
        read -r header
        [[ "${header[0]}" == $'\r' || "${header[0]}" == $'\n' ]] && break
        case "$header" in
            Host:*  ) read ok host < <(echo $header) ;;
            *       )  : ;;
        esac
    done

    case "$path" in
        index.html      ) content_type='text/html'; type=index ;;
        *.html          ) content_type='text/html' ;;
        *.md            ) content_type='text/html'; type=markdown ;;
        *.jpg|*.jpeg    ) content_type='image/jpeg'; type=bin ;;
        *.png           ) content_type='image/png'; type=bin ;;
        *.ico           ) content_type='image/x-icon'; type=bin ;;
        *.js            ) content_type='application/x-javascript' ;;
        *.css           ) content_type='text/css' ;;
        *               ) content_type='application/octet-stream'; type=bin ;;
    esac

    case "$host" in 
        *) root_dir="/home/jianjun/code/shellweb/mini" ;;
    esac

    file_path="${root_dir}/${path}"
    file_header="${root_dir}/tmpl/header.html"
    file_footer="${root_dir}/tmpl/footer.html"

    if [[ -f "$file_path" ]]
    then
        case "$type" in
            bin)
                echo -e "HTTP/1.1 200 OK\r\nContent-Type: $content_type; charset=binary\r\n"
                cat "$file_path"
                exit 0
                ;;
            markdown)
                mk_body=$(markdown $file_path)
                body=$(<$file_header)${mk_body}$(<$file_footer)
                Respond
                ;;
            index)
                body=$(<$file_header)$(<$file_path)$(<$file_footer)
                Respond
                ;;
            *)
                body=$(<"$file_path")
                Respond
                ;;
        esac
    else
        Error404
    fi
}

if [ $# == 0 ]; then
    main
elif [ $# == 1 ]; then
    {
        main
    } < <(echo -e "GET $1 HTTP/1.1\r\nHost: localhost\r\n\r\n")
else
    echo "Usage: $0 [PATH]"
fi
