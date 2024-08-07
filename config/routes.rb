RedmineApp::Application.routes.draw do
  match 'task_overlap_finder', :to => 'task_overlap_finder#index', :via => :get
  match 'task_overlap_finder/search', :to => 'task_overlap_finder#search', :via => :post
end
