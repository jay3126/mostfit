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

    desc "makes all payments according to POS data in uploads"
    task :all_payments do 
      Upload.all.each do |u|
        begin
          puts "starting #{u.directory}"
          csv = FasterCSV.read("uploads/#{u.directory}/loans.csv")
          headers = csv[0]
          csv[1..-1].each_with_index do |row,i|
            begin
              l = Loan.first(:reference => row[headers.index("reference")])
              begin 
                pos = row[headers.index("POS")].to_f
              rescue
                od_principal = row[headers.index("OD Principal")].to_f
                sched_bal = row[headers.index("expected_value")].to_f
                pos = sched_bal + od_principal
              end
              lh_rows = l.loan_history(:scheduled_principal_due.gt => 0, :scheduled_outstanding_principal.gte => pos, :principal_due.gt => 0)
              puts "pos = #{pos}. making #{lh_rows.count} payments" if lh_rows.count > 0
              lh_rows.each do |lh|
              # make the payments
                bid = l.client.center.branch.id
                cid = l.client.center.id
                p = Payment.new(:type => :principal, :amount => lh.scheduled_principal_due, :received_on => lh.date,
                                :received_by_staff_id => 1, :created_by_user_id => 1, :loan_id => l.id, :created_at => DateTime.now,
                                :c_branch_id => bid, :c_center_id => cid)
                p.save!
                print ".".green
                p = Payment.new(:type => :interest, :amount => lh.scheduled_interest_due, :received_on => lh.date,
                                :received_by_staff_id => 1, :created_by_user_id => 1, :loan_id => l.id, :created_at => DateTime.now,
                                :c_branch_id => bid, :c_center_id => cid)

                p.save!
                print ".".green
              end
              l.update_history if lh_rows.count > 0
              print "#{i}-".green
            rescue Exception => x
              print "!".red
              
            end
          end
        rescue Exception => e
          puts e.message
        end
      end
    end
  end
end
                             
