log_file = STDOUT

log_level = :debug

max_connection = 0

default_request_header = { key: 'value' }

save_content = false

add_filter do |filter|
  filter.focus_host = true
  filter.focus_descendants = true
  filter.allow_path = '/test/*'
  filter.deny_path = '/test/xml/*'
  filter.allow_element = 'html/body'
  filter.deny_element = 'html/head'

  filter.allow_mime_type = %r|^text/.*$|
  filter.deny_mime_type = %r|^text/css$|
  filter.max_size = 1000
end
