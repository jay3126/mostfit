namespace :mostfit do
  namespace :periodic do
    require 'fastercsv'

    desc "To be run each day to adjust advances on outstanding loans that have accumulated advances"
    task :adjust_advances_on_loans, :on_date do |t, args|
      USAGE_TEXT = <<USAGE_TEXT
rake mostfit:periodic:adjust_advances_on_loans[<'yyyy-mm-dd'>]
Adjusts advances on outstanding loans that have accumulated advances
This rake task MUST BE RUN before other rake tasks that affect the specified business day
USAGE_TEXT

      MY_TASK_NAME = Constants::Tasks::ADJUST_ADVANCES_ON_LOANS_TASK
      begin
        on_date_str = args[:on_date]
        raise ArgumentError, "Date was not specified" unless (on_date_str and not(on_date_str.empty?))

        on_date = Date.parse(on_date_str)
        raise ArgumentError, "#{on_date} is a future date" if on_date > Date.today

        user_facade = FacadeFactory.instance.get_instance(FacadeFactory::USER_FACADE, nil)
        operator = user_facade.get_operator

        reporting_facade = FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, operator)
        all_loan_IDs_to_adjust_advances = reporting_facade.all_oustanding_loan_IDs_scheduled_on_date_with_advance_balances(on_date)

        loan_facade = FacadeFactory.instance.get_other_facade(FacadeFactory::LOAN_FACADE, reporting_facade)

        errors = []
        all_loan_IDs_to_adjust_advances.each {|on_loan_id|
          begin
            loan_facade.adjust_advance(on_date, on_loan_id)
          rescue => ex
            errors << [on_loan_id, ex.message]
          end
        }
        
        unless errors.empty?
          error_file_name = Constants::Tasks::error_file_name(MY_TASK_NAME, on_date, DateTime.now)
          error_file_path = File.join(Merb.root, 'log', error_file_name)
          FasterCSV.open(error_file_path, "w") do |csv|
            errors.each do |err|
              csv << err
            end
          end
        end
        
      rescue => ex
        p "Error message: #{ex.message}"
        p USAGE_TEXT
      end
    end
  end
end