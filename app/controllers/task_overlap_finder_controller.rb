class TaskOverlapFinderController < ApplicationController
  unloadable

  def index
    # Инициализация переменных
    @start_date = params[:start_date] || Date.today.beginning_of_month
    @end_date = params[:end_date] || Date.today.end_of_month
    @user_id = params[:user_id]
    @project_ids = params[:project_ids] || []
    @status_ids = params[:status_ids] || []
    @tasks = []
    @total_estimated_hours = 0
    @total_total_estimated_hours = 0
    @total_spent_hours = 0

    # Подготовка данных для отображения
    @employees = Group.find_by(lastname: 'Сотрудники').users
                      .where(status: 1) # Выбор только активных учетных записей
                      .order('users.lastname, users.firstname')
    @projects = Project.order(:name)
    @statuses = IssueStatus.order(:name)
  end

  def search
    begin
      # Обработка параметров формы поиска
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      @user_id = params[:user_id]
      @project_ids = params[:project_ids] || []
      @status_ids = params[:status_ids] || []

      # Создание объектов для поиска
      date_range = DateRange.new(Date.parse(@start_date), Date.parse(@end_date))
      assigned_user = AssignedUser.new(@user_id)
      overlap_threshold = Setting.plugin_redmine_task_overlap_finder['overlap_threshold'].to_i

      # Поиск задач
      task_finder = TaskOverlapFinder.new(date_range, assigned_user, @project_ids, @status_ids, overlap_threshold)
      @tasks = task_finder.find_overlapping_tasks

      # Вычисление суммарных значений
      @total_estimated_hours = @tasks.sum { |task_info| task_info[:task].estimated_hours.to_f }
      @total_total_estimated_hours = @tasks.sum { |task_info| TaskOverlapFinder.total_estimated_hours(task_info[:task]).to_f }
      @total_spent_hours = @tasks.sum { |task_info| TaskOverlapFinder.total_spent_hours(task_info[:task], @user_id).to_f }

      # Вывод отладочной информации
      logger.debug "Поиск задач с параметрами: start_date=#{@start_date}, end_date=#{@end_date}, user_id=#{@user_id}, project_ids=#{@project_ids}, status_ids=#{@status_ids}, overlap_threshold=#{overlap_threshold}"
      logger.debug "Найденные задачи: #{@tasks.map { |t| t[:task].id }}"

      # Подготовка данных для отображения
      @employees = Group.find_by(lastname: 'Сотрудники').users.where(status: 1).order('users.lastname, users.firstname')
      @projects = Project.order(:name)
      @statuses = IssueStatus.order(:name)

      # Отображение результатов
      render :index
    rescue ArgumentError => e
      flash[:error] = "Неверный формат даты. Пожалуйста, введите корректные даты."
      redirect_to task_overlap_finder_path
    end
  end
end
