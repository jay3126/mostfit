namespace :mostfit do
  namespace :periodic do
    require 'fastercsv'

    desc "To be run each day to accrue receipts on loans"
    task :account_for_accruals, :on_date do |t, args|
      USAGE_TEXT = <<USAGE_TEXT
rake mostfit:periodic:account_for_accruals[<'yyyy-mm-dd'>]
Account for the accrual transactions recorded on the same date
USAGE_TEXT

      MY_TASK_NAME = Constants::Tasks::ACCOUNT_FOR_ACCRUALS_TASK
      begin
        on_date_str = args[:on_date]
        raise ArgumentError, "Date was not specified" unless (on_date_str and not(on_date_str.empty?))

        on_date = Date.parse(on_date_str)
        raise ArgumentError, "#{on_date} is a future date" if on_date > Date.today

        user_facade = FacadeFactory.instance.get_instance(FacadeFactory::USER_FACADE, nil)
        operator = user_facade.get_operator

        reporting_facade = FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, operator)
        all_accrual_transactions = reporting_facade.all_accrual_transactions_recorded_on_date(on_date)

        errors = []
        bk = MyBookKeeper.new
        all_accrual_transactions.each {|accrual_transaction|
          begin
            bk.account_for_accrual(accrual_transaction)
          rescue => ex
            errors << [accrual_transaction.id, ex.message]
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
