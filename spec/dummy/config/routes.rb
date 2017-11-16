Rails.application.routes.draw do
  get 'redirect' => redirect('/test')
  get 'not_modified' => 'application#not_modified'
  get 'gone' => 'application#gone'
end
