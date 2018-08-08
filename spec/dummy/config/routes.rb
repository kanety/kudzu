Rails.application.routes.draw do
  get 'file' => 'application#file'
  get 'redirect' => redirect('/test/index.html')
  get 'not_modified' => 'application#not_modified'
  get 'gone' => 'application#gone'
  get 'internal_server_error' => 'application#internal_server_error'
  get 'image_file_jp' => 'application#image_file_jp'
  get 'image_file_en' => 'application#image_file_en'
end
