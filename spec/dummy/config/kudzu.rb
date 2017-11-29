log_file STDOUT

log_level :debug

max_connection 0

default_request_header key: 'value'

save_content false

url_filter {
  focus_host true
  focus_descendants true
  allow_path '/test/*'
  deny_path '/test/xml/*'
  allow_element 'html/body'
  deny_element 'html/head'
}

page_filter {
  allow_mime_type %r|^text/.*$|
  deny_mime_type %r|^text/css$|
  max_size 100
}
