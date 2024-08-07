require 'redmine_task_overlap_finder'

Redmine::Plugin.register :redmine_task_overlap_finder do
  name 'Redmine Task Overlap Finder plugin'
  author 'Cheryaev A.A.'
  description 'Plugin to find overlapping tasks by dates and assigned users'
  version '0.0.1'
  url 'http://example.com/path/to/your/plugin'
  author_url 'http://example.com/about'

  # Регистрация пути к контроллеру
  menu :top_menu, :task_overlap_finder, { controller: 'task_overlap_finder', action: 'index' }, caption: 'Поиск пересекающихся задач'
end
