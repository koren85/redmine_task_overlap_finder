require 'redmine_task_overlap_finder'

Redmine::Plugin.register :redmine_task_overlap_finder do
  name 'Redmine Task Overlap Finder plugin'
  author 'Cheryaev A.A.'
  description 'Plugin to find overlapping tasks by dates and assigned users'
  version '0.0.1'
  url 'http://example.com/path/to/your/plugin'
  author_url 'http://example.com/about'


  settings default: {
    'trackers' => [],
    'user_groups' => [],
    'statuses' => []
  }, partial: 'settings/task_overlap_finder_settings'

  # Регистрация нового разрешения
  project_module :task_overlap_finder do
    permission :view_overlapping_tasks, { task_overlap_finder: [:index] }
  end

  # Регистрация пути к контроллеру
  # menu :top_menu, :task_overlap_finder, { controller: 'task_overlap_finder', action: 'index' }, caption: 'Поиск пересекающихся задач'
  # Регистрация пункта меню с проверкой разрешения хотя бы в одном проекте
  menu :top_menu, :task_overlap_finder,
       { controller: 'task_overlap_finder', action: 'index' },
       caption: 'Поиск пересекающихся задач',
       if: Proc.new {
         User.current.logged? &&
           User.current.projects.any? { |project| User.current.allowed_to?(:view_overlapping_tasks, project) }
       }
end


# Подключение хука
require_relative 'app/hooks/task_overlap_finder_hook_listener'