max_connection 0
max_retry 3

default_request_header key: 'value'

add_filter do
  focus_host true
  focus_descendants true
  allow_path '/test/*'
  deny_path '/test/xml/*'
  allow_element 'html/body'
  deny_element 'html/head'

  allow_mime_type %r|^text/.*$|
  deny_mime_type %r|^text/css$|
  max_size 5000
end
