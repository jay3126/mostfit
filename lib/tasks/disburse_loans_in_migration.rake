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
  namespace :suryoday do

    desc "disburses loans which are uploaded"
    task :disburse_uploaded_loans do
      require 'fastercsv'
      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:suryoday:disburse_uploaded_loans
Convert lendings tab in the upload file to a .csv and put them into <directory>
USAGE_TEXT

      begin
        lending_ids_to_disburse = Lending.all(:status => :new_loan_status).aggregate(:id)

        lending_ids_to_disburse.each do |lo|
          loan = Lending.get(lo)
          next if loan.nil?
          default_currency = MoneyManager.get_default_currency

          #approving the loan.
          new_loan_status = LoanLifeCycle::APPROVED_LOAN_STATUS
          current_status = loan.status
          loan.status = new_loan_status
          loan.save!       #saving the loan with its new status.

          #making the entry in loan_status_change model.
          LoanStatusChange.record_status_change(loan, current_status, new_loan_status, loan.approved_on_date)
          loan.setup_on_approval

          accounting_facade = FacadeFactory.instance.get_instance(FacadeFactory::ACCOUNTING_FACADE, User.first)
          payment_facade = FacadeFactory.instance.get_instance(FacadeFactory::PAYMENT_FACADE, User.first)

          #making the disbursement entry.
          accounting_facade = FacadeFactory.instance.get_instance(FacadeFactory::ACCOUNTING_FACADE, User.first)
          payment_facade = FacadeFactory.instance.get_instance(FacadeFactory::PAYMENT_FACADE, User.first)

          payment_transaction = PaymentTransaction.record_payment(loan.to_money[:disbursed_amount], 'payment',
              Constants::Transaction::PAYMENT_TOWARDS_LOAN_DISBURSEMENT, '', 'lending',
              loan.id, 'client', loan.loan_borrower.counterparty_id, loan.administered_at_origin, loan.accounted_at_origin, loan.disbursed_by_staff,
              loan.disbursal_date, User.first.id)

          payment_allocation = loan.allocate_payment(payment_transaction, Constants::Transaction::LOAN_DISBURSEMENT, make_specific_allocation = nil,
              specific_principal_money_amount = nil, specific_interest_money_amount = nil, '')
          accounting_facade.account_for_payment_transaction(payment_transaction, payment_allocation)
        end
      rescue => ex
        p "An exception occurred: #{ex}"
        p USAGE
      end
    end
  end
end