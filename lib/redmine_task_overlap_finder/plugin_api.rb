module RedmineTaskOverlapFinder
  class PluginAPI
    def self.find_tasks(date_range, assigned_user, project_ids = [], status_ids = [])
      overlap_finder = TaskOverlapFinder.new(date_range, assigned_user, project_ids, status_ids)
      tasks = overlap_finder.find_overlapping_tasks

      # Вывод отладочной информации
      Rails.logger.debug "Вызов find_tasks с параметрами: date_range=#{date_range.inspect}, assigned_user=#{assigned_user.inspect}, project_ids=#{project_ids.inspect}, status_ids=#{status_ids.inspect}"
      Rails.logger.debug "Найденные задачи внутри find_tasks: #{tasks.inspect}"

      tasks
    end
  end
end
