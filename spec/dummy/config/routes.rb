Rails.application.routes.draw do
  get 'file' => 'application#file'
  get 'redirect' => redirect('/test/index.html')
  get 'not_modified' => 'application#not_modified'
  get 'gone' => 'application#gone'
  get 'internal_server_error' => 'application#internal_server_error'
end
