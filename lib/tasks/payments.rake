require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  namespace :payments do 
    desc "Deletes all payments on given date range"
   # task :delete, :begin_date, :end_date  do |task, args|
    task :delete do 

      t1 = Time.now
      # if args[:begin_date].nil?
      #   puts
      #   puts "USAGE: rake mostfit:delete_payments:payments[<from_date>,<to_date>]"
      #   puts
      #   puts "NOTE: Make sure there are no spaces after and before the comma separating the two arguments." 
      #   puts "      The from_date has to be supplied. If the to_date is not supplied it is assumed to be today."
      #   puts "      The format for the date is DD-MM-YYYY. The date has to be enclosed in single quotes. For 6th August 2011 it shall be '06-08-2011'."
      #   puts "      If you want to delete payment for only one date then please specify the begin_date and end_date as the same dates."
      #   puts
      #   puts "EXAMPLE: rake mostfit:delete_payments:payments['06-07-2011']"
      #   puts "         rake mostfit:delete_payments:payments['06-07-2011','13-07-2011']"
      #   puts "         rake mostfit:delete_payments:payments['06-07-2011','06-07-2011'] for delete single date payments"
      #   flag = 0

      # else
      #   flag =1
      #   begin_date = Date.strptime(args[:begin_date], "%d-%m-%Y")
      # end

      # if args[:end_date].nil?
      #   end_date = Date.today
      # else
      #   end_date = Date.strptime(args[:end_date], "%d-%m-%Y")
      # end
      
      # if begin_date.nil? or end_date.nil?
      #   # Dont display this ERROR message if you have already displayed the USAGE message
      #   if flag ==1
      #     puts 
      #     puts "ERROR: Please give the arguments in the proper format. For 6th August 2011 it shall be '06-08-2011'"
      #   end

      # elsif begin_date <= end_date
     # payments = Payment.all(:received_on.gte => begin_date, :received_on.lte => end_date)
      payments = Payment.all(:received_on.gte => Date.new(2011, 10, 05), :received_on.lte => Date.new(2011, 10, 06))
      loan_ids = payments.aggregate(:loan_id)
      loans_count = loan_ids.count
      payments_count = payments.count

     # puts "Total payments to be deleted between #{begin_date} and #{end_date} is #{payments_count} of #{loans_count} loans."
      puts
      puts "Begining to delete the payments..."
      puts

      #deleting all the payments.
      payments.each do |p|
        p.destroy!
      end

      puts "All the payments have been deleted. Now history of the loan will be repaired."
      puts
      puts "Repair history of loans is now starting.."

      #repairing of loan_history.
      loan_ids.each do |l|
        Loan.get(l).update_history
      end

      t2 = Time.now
      puts
      puts "Payments for the given date range has been deleted and history of the loans repaired."
      puts "Total time taken for the whole process is #{t2-t1} seconds."

      # else
      #   puts "ERROR: The begin date #{begin_date} is greater than the end date #{end_date}."
    end
  end
end
#end
