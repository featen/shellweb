#!/bin/bash

LANG=C
LC_ALL=C

RespondHtml ()
{
    echo "HTTP/1.1 200 OK"
    echo "Connection: close"
    echo "Content-Type: $content_type; charset=utf-8"
    echo "Content-Length: $((${#body}+1))"
    echo "Host: $host"
    echo -e "Date: $(TZ=UTC; date '+%a, %d %b %Y %T GMT')\r\n"
    echo "$body"
    exit 0
}

Error404 ()
{
    echo 'HTTP/1.1 404 Not Found'
    echo -e "\n404 Not Found"
    exit 0
}

Error405 ()
{
    echo 'HTTP/1.1 405 Method Not Allowed'
    echo -e "\n405 Method Not Allowed"
    exit 0
}

main() {
    read -r request
    read method path protocol < <(echo $request)
    if [ "$method" != 'GET' ]; then
        Error405
    fi
    path="${path%%\?*}"


    while :
    do
        read -r header
        [[ "${header[0]}" == $'\r' || "${header[0]}" == $'\n' ]] && break
        case "$header" in
            Host:*) read ok host < <(echo $header) ;;
            *)  : ;;
        esac
    done

    
    [[ "${#path}" == "0" || "${#path}" == 1 ]] && path="/index.html"

    case "$path" in
        /private/*) Error404 ;;
        /index.html) content_type='text/html'; type=index ;;
        *.html) content_type='text/html' ;;
        *.md) content_type='text/html'; type=markdown ;;
        *.jpg|*.jpeg) content_type='image/jpeg'; type=bin ;;
        *.png) content_type='image/png'; type=bin ;;
        *.ico) content_type='image/x-icon'; type=bin ;;
        *.js) content_type='application/x-javascript' ;;
        *.css) content_type='text/css' ;;
        *) content_type='application/octet-stream'; type=bin ;;
    esac

    case "$host" in 
        *.featen.com) root_dir="/home/jianjun/code/shellweb/featen" ;;
        *.meicard.com) root_dir="/home/jianjun/code/shellweb/meicard" ;;
        *) root_dir="/home/jianjun/code/shellweb/mini" ;;
    esac

    file_path="${root_dir}/${path}"
    file_header="${root_dir}/tmpl/header.html"
    file_footer="${root_dir}/tmpl/footer.html"



    if [[ -f "$file_path" ]]
    then
        case "$type" in
            bin)
                echo 'HTTP/1.1 200 OK'
                echo -e "Content-Type: $content_type; charset=binary\n"
                cat "$file_path"
                exit 0
                ;;
            markdown)
                mk_body=$(markdown $file_path)
                page_header=$(<$file_header)
                page_footer=$(<$file_footer)
                body=${page_header}${mk_body}${page_footer}
                RespondHtml
                ;;
            index)
                index_body=$(<$file_path)
                page_header=$(<$file_header)
                page_footer=$(<$file_footer)
                body=${page_header}${index_body}${page_footer}
                RespondHtml
                ;;
            *)
                body=$(<"$file_path")
                RespondHtml
                ;;
        esac
    else
        Error404
    fi
}

main "$@"
