namespace :mostfit do
  namespace :periodic do
    require 'fastercsv'

    desc "To be run each day to accrue receipts on loans"
    task :accrue_on_loans, :on_date do |t, args|
      USAGE_TEXT = <<USAGE_TEXT
rake mostfit:periodic:accrue_on_loans[<'yyyy-mm-dd'>]
Accrues on loans as appropriate, including regular accrual,
broken-period interest accrual, and reversal of broken-period interest accrual
USAGE_TEXT

      MY_TASK_NAME = Constants::Tasks::ACCRUE_ON_LOANS_TASK
      begin
        on_date_str = args[:on_date]
        raise ArgumentError, "Date was not specified" unless (on_date_str and not(on_date_str.empty?))

        on_date = Date.parse(on_date_str)
        raise ArgumentError, "#{on_date} is a future date" if on_date > Date.today

        branches_ids = BizLocation.all('location_level.level' => 1).map(&:id)
        unless branches_ids.blank?
          created_by = User.first
          performed_by = User.first.staff_member
          BodProcess.create_default_bod_for_location(branches_ids, on_date, on_date)
          BodProcess.bod_process_for_location(branches_ids, performed_by.id, created_by.id, on_date)
        end
      rescue => ex
        p "Error message: #{ex.message}"
        p USAGE_TEXT
      end
    end
  end
end