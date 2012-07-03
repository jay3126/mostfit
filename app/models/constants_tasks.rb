module Constants
  module Tasks
    
    ACCRUE_ON_LOANS_TASK = :accrue_on_loans_task
    ALL_TASKS = [ACCRUE_ON_LOANS_TASK]

    def self.error_file_name(task_name, on_date, date_time = DateTime.now)
      raise Errors::InvalidConfigurationError, "Task name: #{task_name} does not match known tasks" unless 
        ALL_TASKS.include?(task_name)

      "errors.#{task_name}.on.#{on_date.display}.at.#{date_time}"
    end

  end
end
