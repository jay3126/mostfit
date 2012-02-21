# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"
require "fastercsv"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace :mostfit do
  namespace :migration do
    desc "given a date delete all the payments and update the loan histories of the loans associated with"
    task :delete_payments, :received_on_or_after do |t, args|
      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:migration:delete_payments[<'received_after_date'>]
Date has to be in the format DD-MM-YYYY
USAGE_TEXT

      begin 
        date_str = args[:received_on_or_after]
        raise ArgumentError, "Please supply a valid date: #{date_str}" unless (date_str and (not date_str.empty?))
        date = Date.parse(date_str) 
        status_file_path = File.join(Merb.root, "docs", "deleted_payments_after_#{date}.csv")
        deleted_payments = []
        status_hash = {}
        HEADER = ["PAYMENT_ID","PAYMENT_AMOUNT", "STATUS", "LOAN_ID", "TOS_BEFORE_DELETION", "TOS_AFTER_DELETION"]
        FasterCSV.open(status_file_path, "w") do |status_csv|
          status_csv << HEADER
        end
        
        payment_ids = Payment.all(:received_on.gte => date).aggregate(:id)
        payment_ids.each do |payment_id|
          p = Payment.get(payment_id)
          l = p.loan
          today = Date.today
          tos_before = l.actual_outstanding_total_on(today)
          status, payment = l.delete_payment(p, User.first)
          tos_after = l.actual_outstanding_total_on(today)
          status_hash[payment_id] = status
          FasterCSV.open(status_file_path, "a") do |status_csv|
            status_csv << [payment.id, payment.amount, status, l.id, tos_before, tos_after]
          end
        end
       
        ap status_hash
      rescue => ex
        puts USAGE
      end

    end
  end
end
