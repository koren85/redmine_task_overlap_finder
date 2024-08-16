module TaskOverlapFinderHookListener
  class ViewIssuesShowDetailsBottomHook < Redmine::Hook::ViewListener
    def view_issues_show_details_bottom(context = {})
      issue = context[:issue]
      user = User.current


      # Проверка наличия разрешения
      return '' unless user.allowed_to?(:view_overlapping_tasks, issue.project) || user.admin?

      # Получение настроек плагина
      settings = Setting.plugin_redmine_task_overlap_finder

      # Проверка трекера
      return '' unless settings['trackers'].include?(issue.tracker_id.to_s)

      # Проверка группы пользователей (исполнитель задачи должен входить в одну из указанных групп)
      assigned_user = issue.assigned_to
      return '' unless assigned_user && assigned_user.groups.any? { |group| settings['user_groups'].include?(group.id.to_s) }

      # Проверка статуса задачи
      return '' unless settings['statuses'].include?(issue.status_id.to_s)

      render_overlapping_tasks(context, issue)
    end

    def controller_issues_edit_after_save(context = {})
      issue = context[:issue]
      user = User.current


      # Проверка наличия разрешения
      return unless user.allowed_to?(:view_overlapping_tasks, issue.project)

      # Получение настроек плагина
      settings = Setting.plugin_redmine_task_overlap_finder

      # Проверка трекера
      return unless settings['trackers'].include?(issue.tracker_id.to_s)

      # Проверка группы пользователей (исполнитель задачи должен входить в одну из указанных групп)
      assigned_user = issue.assigned_to
      return '' unless assigned_user && assigned_user.groups.any? { |group| settings['user_groups'].include?(group.id.to_s) }

      # Проверка статуса задачи
      return unless settings['statuses'].include?(issue.status_id.to_s)

      # Проверка изменений в сроках или назначенном исполнителе
      if issue.saved_change_to_start_date? || issue.saved_change_to_due_date? || issue.saved_change_to_assigned_to_id?
        check_and_flash_overlapping_tasks(context, issue)
      end
    end

    private

    def render_overlapping_tasks(context, issue)
      overlapping_tasks = find_overlapping_tasks(issue)
      return '' if overlapping_tasks.empty?

      context[:controller].send(:render_to_string, {
        partial: 'task_overlap_finder/overlapping_tasks',
        locals: { issue: issue, overlapping_tasks: overlapping_tasks }
      })
    end

    def check_and_flash_overlapping_tasks(context, issue)
      overlapping_tasks = find_overlapping_tasks(issue)
      unless overlapping_tasks.empty?
        links = overlapping_tasks.map do |task|
          "##{task.id} - " + context[:controller].view_context.link_to(task.subject, context[:controller].view_context.issue_path(task))
        end.join(', ')

        context[:controller].flash[:warning] = "Внимание! Эта задача пересекается по срокам и исполнителю с другими задачами: #{links}"
      end
    end

    def find_overlapping_tasks(issue)
      date_range = DateRange.new(issue.start_date, issue.due_date)
      assigned_user = AssignedUser.new(issue.assigned_to_id)

      RedmineTaskOverlapFinder::PluginAPI.find_tasks(date_range, assigned_user, [issue.project_id], [issue.status_id]).where.not(id: issue.id)
    end
  end
end
