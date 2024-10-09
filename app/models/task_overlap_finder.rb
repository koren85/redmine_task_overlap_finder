class TaskOverlapFinder
  def initialize(date_range, assigned_user, project_ids, status_ids, overlap_threshold)
    @date_range = date_range
    @assigned_user = assigned_user
    @project_ids = project_ids
    @status_ids = status_ids
    @overlap_threshold = overlap_threshold
  end

  def find_overlapping_tasks
    tasks = Issue.where(assigned_to_id: @assigned_user.id)
                 .where('start_date <= ? AND due_date >= ?', @date_range.end_date, @date_range.start_date)

    tasks = tasks.where(project_id: @project_ids) unless @project_ids.empty?
    tasks = tasks.where(status_id: @status_ids) unless @status_ids.empty?

    # Добавление расчета количества пересекающихся дней
    overlapping_tasks = tasks.map do |task|
      overlap_days = calculate_overlap_days(@date_range, task.start_date, task.due_date)
      overlap_percentage = self.class.calculate_overlap_percentage(@date_range, task)
      { task: task, overlap_days: overlap_days, overlap_percentage: overlap_percentage }
    end

    # Сортировка задач по количеству пересекающихся дней (от максимального к минимальному)
    overlapping_tasks.sort_by { |t| -t[:overlap_days] }
  end

  def self.total_estimated_hours(issue)
    return issue.estimated_hours.to_f.round unless issue.children.any?
    issue.children.sum(:estimated_hours).to_f.round
  end

  def self.total_spent_hours(issue, user_id)
    issue.time_entries.where(user_id: user_id).sum(:hours).to_f.round
  end

  def self.calculate_overlap_percentage(range, task)
    overlap_start = [range.start_date, task.start_date].max
    overlap_end = [range.end_date, task.due_date].min
    overlap_days = (overlap_end - overlap_start).to_i + 1

    total_duration = (task.due_date - task.start_date).to_i + 1
    ((overlap_days.to_f / total_duration) * 100).round
  end

  private

  def calculate_overlap_days(range, start_date, due_date)
    overlap_start = [range.start_date, start_date].max
    overlap_end = [range.end_date, due_date].min
    [(overlap_end - overlap_start + 1).to_i, 0].max
  end
end
