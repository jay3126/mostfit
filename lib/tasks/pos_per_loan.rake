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
    desc "This rake task will give you a POS per loan as on 29th Feb and 31st March 2012"
    task :pos_per_loan do
      t1 = Time.now
      loan_ids = Loan.all.aggregate(:id)
      date1 = Date.new(2012, 02, 29)
      date2 = Date.new(2012, 03, 31)
      sl_no = 0

      f = File.open("tmp/pos_per_loan_#{DateTime.now.to_s}.csv", "w")
      f.puts("\"Sl. No.\", \"Branch Name\", \"Center Name\", \"Client Name\", \"Loan System Id\", \"Loan Reference Number\", \"POS as on 29th Feb 2012\", \"POS as on 31st March 2012\", \"POS as on 29th Feb 2012 (without rounding)\", \"POS as on 31st March 2012 (without rounding)\"")

      loan_ids.each do |l|
        loan = Loan.get(l)

        sl_no += 1

        loan_id = loan.id
        loan_reference_number = loan.reference
        client = Client.get(loan.client_id)
        client_name = client.name
        center_name = client.center.name
        branch_name = client.center.branch.name

        pos_as_on_29th_feb_2012 = loan.actual_outstanding_principal_on(date1).round(2)
        pos_as_on_31st_march_2012 = loan.actual_outstanding_principal_on(date2).round(2)

        pos_as_on_29th_feb_2012_without_rounding = loan.actual_outstanding_principal_on(date1)
        pos_as_on_31st_march_2012_without_rounding = loan.actual_outstanding_principal_on(date2)

        f.puts("#{sl_no}, \"#{branch_name}\", \"#{center_name}\", \"#{client_name}\", #{loan_id}, \"#{loan_reference_number}\", #{pos_as_on_29th_feb_2012}, #{pos_as_on_31st_march_2012}, #{pos_as_on_29th_feb_2012_without_rounding}, #{pos_as_on_31st_march_2012_without_rounding}")
      end
      f.close
      t2 = Time.now
      puts "Time taken: #{t2-t1} seconds"
      puts "The file is saved in tmp directory with the filename pos_per_loan"
    end
  end
end
