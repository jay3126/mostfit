require "rubygems"

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
  namespace :payments do
    desc "Fill fee ids in payments"
    task :fill_fees do
      ids = Payment.all(:type => :fees, :fee_id => nil, :comment => "card fee").map{|x| x.id}
      repository.adapter.execute("UPDATE payments SET fee_id=3 WHERE id in (#{ids.join(",")})")

      ids=Payment.all(:type => :fees, :fee_id => nil, :comment => "processing fee 3%").map{|x| x.id}
      repository.adapter.execute("UPDATE payments SET fee_id=1 WHERE id in (#{ids.join(",")})")      

      ids = (Payment.all(:type => :fees, :fee_id => nil, :comment => "processing fee 2.5%") + Payment.all(:type => :fees, :fee_id => nil, :comment => "processing fee")).map{|x| x.id}
      repository.adapter.execute("UPDATE payments SET fee_id=2 WHERE id in (#{ids.join(",")})")
    end
  end

  namespace :fees do
    desc "levy fees on objects"
    task :levy do
      Client.all(:fields => [:id]).each{|cid|
        c = Client.get(cid.id)
        next unless c
        c.levy_fees
        c.loans.each{|l|
          l.levy_fees
        }
      }
    end

<<<<<<< HEAD
    desc "Pay Levied Fees for loans whose payment of fees has not been recorded."
    task :pay do
      puts "starting"
      t0 = Time.now
      Merb.logger.info! "Start mock:all_payments rake task at #{t0}"
      busy_user = User.get(1)
      count = 0
      puts "1: #{Time.now - t0}"
      loans = Loan.all - Loan.all('payments.type' => :fees)
      loans.each do |loan|
        sql = " INSERT INTO `payments` (`received_by_staff_id`, `amount`, `type`, `created_by_user_id`, `loan_id`, `received_on`, `client_id`, `fee_id`) VALUES ";
        _t0 = Time.now
        staff_member = loan.client.center.manager
        p "Doing loan No. #{loan.id}...."
        loan.history_disabled = true  # do not update the hisotry for every payment
        values = []
        if loan.applicable_fees.empty?
          puts 'the loan #{loan.id} has no applicable fees'
        else
          loan.applicable_fees.each do |applicable_fee|
            amount = applicable_fee.amount
            date = applicable_fee.applicable_on
            values << "(#{staff_member.id}, #{amount}, 3, 1, #{loan.id}, '#{date.strftime("%Y-%m-%d")}', #{loan.client.id}, #{applicable_fee.fee_id})"
            count += 1
          end
          puts "done constructing sql in #{Time.now - _t0}"
          if not values.empty?
            sql += values.join(",")
            repository.adapter.execute(sql)
            puts "done executing sql in #{Time.now - _t0}"
            puts "---------------------"
          end
        end
      end
      puts "Done #{count} loans. Total time: #{Time.now - t0} secs"
||||||| merged common ancestors
    desc "pay levied fees"
    task :pay do
=======

    desc "pay all applicable fees"
    task :pay_all do
      ApplicableFee.all.each do |af|
        m = Kernel.const_get(af.applicable_type).get(af.applicable_id)
        rb = af.applicable_type == "Loan" ? m.client.center.manager : m.center.manager
        p = Payment.new(:received_on => af.applicable_on, :received_by => rb, :amount => af.amount, :type => :fees, :fee_id => af.fee_id,
                        :created_by_user_id => 1, :loan_id => m.is_a? (Loan) ? m.id : nil, :client_id => m.is_a? (Loan) ? m.client.id : m.id)
        if p.save
          puts "Paid #{p.amount} as #{af.fee.name}"
        else
          puts "failed to pay applicable fee #{af.id}"
        end
      end
>>>>>>> new-layout
    end


  end


end
