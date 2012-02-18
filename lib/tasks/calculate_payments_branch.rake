# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"
require "ap"
# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')


namespace :mostfit do
  namespace :migration do

    desc "calculates the sum of all principal payments per loan for detecting errors"
    task :display_pos_against_payments, :branch_name do |t, args|
      USAGE = "[bin/]rake mostfit:migration:display_pos_against_payments[<'Branch name'>]"
      begin
        branch_name_str = args[:branch_name]
        raise ArgumentError, USAGE unless (branch_name_str and !(branch_name_str.empty?))
        branch = Branch.first(:name => branch_name_str)
        raise ArgumentError, "No branch found with name #{branch_name_str}" unless branch
        center_ids = branch.centers.aggregate(:id)
        client_ids = Client.all(:center_id => center_ids).aggregate(:id)
        loan_ids = Loan.all(:client_id => client_ids).aggregate(:id)
        total_loan_amounts = Loan.all(:id => loan_ids).aggregate(:amount.sum)
        payments = Payment.all(:loan_id => loan_ids, :type => :principal).aggregate(:amount.sum)
        puts "Total Loan Amount: Rs. #{total_loan_amounts}/-"
        puts "Total Principal Receipts: Rs. #{payments}/-"
        puts "Principal Out Standing [Total Loan Amount - Total Principal Receipts] (POS): Rs. #{total_loan_amounts - payments}/-"
        principal_payments_loanwise = Loan.all(:id => loan_ids).map{|x| [x.id, x.amount, x.client.reference, Payment.all(:loan_id => x.id, :type => :principal).aggregate(:amount.sum)]}
        ap principal_payments_loanwise
      rescue => ex
        puts "An error occurred: #{ex}"
      end
    end
  end
end
