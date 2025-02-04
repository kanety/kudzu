Rails.application.routes.draw do
  get 'file', to: 'application#file'
  get 'redirect', to: redirect('/test/index.html')
  get '/test/redirect_to_other_host', to: redirect(host: 'sub.localhost', path: '/test/index.html')
  get 'not_modified', to: 'application#not_modified'
  get 'gone', to: 'application#gone'
  get 'internal_server_error', to: 'application#internal_server_error'
  get 'image_file_jp', to: 'application#image_file_jp'
  get 'image_file_en', to: 'application#image_file_en'
end
