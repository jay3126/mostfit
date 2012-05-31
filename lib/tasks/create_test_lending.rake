# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace :mostfit do
  namespace :lending do
    desc "create instances of loans for testing of improvements"
    task :create_test_lending do |t, args|
      require 'date'
      require 'spec/factories'

      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:lending:create_test_lending
Create some test lending for testing
USAGE_TEXT

      begin

        administered_at = Factory(:biz_location)
        accounted_at    = Factory(:biz_location)

        client_count = 20
        performed_by = 21
        recorded_by = 23
        beginning_applied_on_date = Date.parse('2012-04-01')
        clients = 1.upto(client_count).collect {|n| Factory(:client)}
        clients.each{|client| ClientAdministration.assign(administered_at,accounted_at,client,performed_by, recorded_by, beginning_applied_on_date)}
        

        @from_lending_product = Factory(:lending_product)

        @principal_and_interest_amounts = { }
        @principal_amounts            = [170.18, 171.03, 171.88, 172.74, 173.60, 174.46, 175.33, 176.21, 177.08, 177.97, 178.85, 179.74, 180.64, 181.54, 182.44, 183.35, 184.27, 185.18, 186.11, 187.03, 187.97, 188.90, 189.84, 190.79, 191.74, 192.69, 193.65, 194.62, 195.59, 196.56, 197.54, 198.53, 199.52, 200.51, 201.51, 202.51, 203.52, 204.53, 205.55, 206.58, 207.61, 208.64, 209.68, 210.73, 211.77, 212.83, 213.89, 214.96, 216.03, 217.10, 218.18, 146.30]
        @principal_money_amounts      = MoneyManager.get_money_instance(*@principal_amounts)
        zero_money_amount             = MoneyManager.default_zero_money
        @total_principal_money_amount = @principal_money_amounts.inject(zero_money_amount) { |sum, money_amt| sum + money_amt }

        @interest_amounts            = [49.82, 48.97, 48.12, 47.26, 46.40, 45.54, 44.67, 43.79, 42.92, 42.03, 41.15, 40.26, 39.36, 38.46, 37.56, 36.65, 35.73, 34.82, 33.89, 32.97, 32.03, 31.10, 30.16, 29.21, 28.26, 27.31, 26.35, 25.38, 24.41, 23.44, 22.46, 21.47, 20.48, 19.49, 18.49, 17.49, 16.48, 15.47, 14.45, 13.42, 12.39, 11.36, 10.32, 9.27, 8.23, 7.17, 6.11, 5.04, 3.97, 2.90, 1.82, 0.73]
        @interest_money_amounts      = MoneyManager.get_money_instance(*@interest_amounts)
        @total_interest_money_amount = @interest_money_amounts.inject(zero_money_amount) { |sum, money_amt| sum + money_amt }

        1.upto(@principal_amounts.length) { |num|
          principal_and_interest                                           = { }
          principal_and_interest[Constants::Transaction::PRINCIPAL_AMOUNT] = @principal_money_amounts[num - 1]
          principal_and_interest[Constants::Transaction::INTEREST_AMOUNT]  = @interest_money_amounts[num - 1]
          @principal_and_interest_amounts[num]                             = principal_and_interest
        }

        @principal_and_interest_amounts[0] = {
            Constants::Transaction::PRINCIPAL_AMOUNT => @total_principal_money_amount,
            Constants::Transaction::INTEREST_AMOUNT  => @total_interest_money_amount
        }

        @name = "test loan template schedule"
        @lst                           = LoanScheduleTemplate.create_schedule_template(@name, @total_principal_money_amount, @total_interest_money_amount, @principal_money_amounts.length, MarkerInterfaces::Recurrence::WEEKLY, @from_lending_product, @principal_and_interest_amounts)

        applied_on_date = beginning_applied_on_date

        clients.each do |client|
          lan                            = "#{DateTime.now}_#{client.id}"
          for_amount                     = @total_principal_money_amount
          for_borrower_id                = client.id
          applied_on_date                += 1
          scheduled_disbursal_date       = applied_on_date + 7
          scheduled_first_repayment_date = scheduled_disbursal_date + 7
          repayment_frequency            = MarkerInterfaces::Recurrence::WEEKLY
          tenure                         = 52
          administered_at_origin         = administered_at.id
          accounted_at_origin            = accounted_at.id
          applied_by_staff               = performed_by
          recorded_by_user               = recorded_by

          loan = Lending.create_new_loan(for_amount, repayment_frequency, tenure, @from_lending_product, for_borrower_id, administered_at_origin, accounted_at_origin, applied_on_date, scheduled_disbursal_date, scheduled_first_repayment_date, applied_by_staff, recorded_by_user, lan)
          LoanAdministration.assign(administered_at, accounted_at, loan, performed_by, recorded_by, beginning_applied_on_date)
        end
      rescue => ex
        puts "An error occurred: #{ex.message}"
        puts USAGE
      end
    end
  end
end
