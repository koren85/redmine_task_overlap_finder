class TaskOverlapFinder
  def initialize(date_range, assigned_user, project_ids, status_ids)
    @date_range = date_range
    @assigned_user = assigned_user
    @project_ids = project_ids
    @status_ids = status_ids
  end

  def find_overlapping_tasks
    tasks = Issue.where(assigned_to_id: @assigned_user.id)
                 .where('start_date >= ? AND due_date <= ?', @date_range.start_date, @date_range.end_date)

    tasks = tasks.where(project_id: @project_ids) unless @project_ids.empty?
    tasks = tasks.where(status_id: @status_ids) unless @status_ids.empty?

    # Вывод отладочной информации
    Rails.logger.debug "SQL запрос для поиска задач: #{tasks.to_sql}"
    Rails.logger.debug "Запрос в find_overlapping_tasks: assigned_to_id=#{@assigned_user.id}, date_range=#{@date_range.inspect}, project_ids=#{@project_ids.inspect}, status_ids=#{@status_ids.inspect}"
    Rails.logger.debug "Найденные задачи в find_overlapping_tasks: #{tasks.inspect}"

    tasks
  end

  def self.total_estimated_hours(issue)
    return issue.estimated_hours.to_f.round unless issue.children.any?
    issue.children.sum(:estimated_hours).to_f.round
  end

  def self.total_spent_hours(issue, user_id)
    issue.time_entries.where(user_id: user_id).sum(:hours).to_f.round
  end
end
