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
    desc "This rake task modifies the payments for given loan ids to match POS for March 2012 for Katraj branch"
    task :march_pos_matching do
      t1 = Time.now
      loan_ids_25_diff = [7633,7634,7635,7636,9611,9612,9613,9614,9615,9616,9617,9618,9619,9620,9621]
      loan_ids_83_diff = [6912,6916,6918,6982,7010,7011,7012,7013,7014,7015,7016,7017,7018,7019,7020,7021,8801,8815,8852,8853,8854,8855,8856,8857,8858,8859,8860]
      loan_ids_95_diff = [6843,6844,6847,6848,6849,8618,8619,8620,8621]
      loan_ids_109_diff = [6913,6914,6915,6917,6976,6977,6978,6979,6980,6981,8724,8725,8726,8727,8728,8729,8730,8731,8732,8791,8792,8793,8794,8795,8796,8797,8798,8799,8800,8802,8803,8804,8805,8806,8807,8808,8809,8810,8811,8812,8813,8814]
      loan_ids_112_diff = [13709,13710,13715,14063,14064,14065,14066,14067,14068,14069,14070,14071,14083,14084,14085]
      loan_ids_126_diff = [6841,6842,6845,6846,6850,8615,8616,8617,8622]
      loan_ids_140_diff = [13551,13642,13643,13666,13667,13668,13669,13840,13960,13961,13962,13963,13964,13965,13966,13967,14000,14001,14002,14003,14004,14005]
      loan_ids_154_diff = [6689,6691,6696,6697,6699,6700,6701,8355,8356,8363,8364,8365,8377,8378,8379,8380,8381,8385,8386]
      loan_ids_172_diff = [6670,6671,6672,6673,6674,6675,8320,8321,8323,8325]
      loan_ids_191_diff = [6469,6470,6471,6472,6473,6475,6476,6477,6592,6593,8017,8018,8019,8020,8021,8022,8023,8024,8026,8188,8189,8190]
      loan_ids_exceptions_diff = [13701,13702,13703,14051,14052]

      #correcting payment for Rs.25 diff in payment.
      Payment.all(:loan_id => loan_ids_25_diff, :received_on => Date.new(2012, 03, 21)).each do |p|
        if p.type == :principal
          p.amount = 604
        elsif p.type == :interest
          p.amount = 246
        end
        p.save
      end
      #updating history of loans.
      loan_ids_25_diff.each do |l|
        loan = Loan.get(l)
        loan.update_history
      end

      #correcting payment for Rs.83 diff in payment.
      Payment.all(:loan_id => loan_ids_83_diff, :received_on => Date.new(2012, 03, 21)).each do |p|
        if p.type == :principal
          p.amount = 595
        elsif p.type == :interest
          p.amount = 155
        end
        p.save
      end
      #updating history of loans.
      loan_ids_83_diff.each do |l|
        loan = Loan.get(l)
        loan.update_history
      end

      #correcting payment for Rs.95 diff in payment.
      Payment.all(:loan_id => loan_ids_95_diff, :received_on => Date.new(2012, 03, 21)).each do |p|
        if p.type == :principal
          p.amount = 607
        elsif p.type == :interest
          p.amount = 143
        end
        p.save
      end
      #updating history of loans.
      loan_ids_95_diff.each do |l|
        loan = Loan.get(l)
        loan.update_history
      end

      #correcting payment for Rs.109 diff in payment.
      Payment.all(:loan_id => loan_ids_109_diff, :received_on => Date.new(2012, 03, 21)).each do |p|
        if p.type == :principal
          p.amount = 784
        elsif p.type == :interest
          p.amount = 216
        end
        p.save
      end
      #updating history of loans.
      loan_ids_109_diff.each do |l|
        loan = Loan.get(l)
        loan.update_history
      end

      #correcting payment for Rs.112 diff in payment.
      Payment.all(:loan_id => loan_ids_112_diff, :received_on => Date.new(2012, 03, 21)).each do |p|
        if p.type == :principal
          p.amount = 614
        elsif p.type == :interest
          p.amount = 136
        end
        p.save
      end
      #updating history of loans.
      loan_ids_112_diff.each do |l|
        loan = Loan.get(l)
        loan.update_history
      end

      #correcting payment for Rs.126 diff in payment.
      Payment.all(:loan_id => loan_ids_126_diff, :received_on => Date.new(2012, 03, 21)).each do |p|
        if p.type == :principal
          p.amount = 801
        elsif p.type == :interest
          p.amount = 199
        end
        p.save
      end
      #updating history of loans.
      loan_ids_126_diff.each do |l|
        loan = Loan.get(l)
        loan.update_history
      end

      #correcting payment for Rs.140 diff in payment.
      Payment.all(:loan_id => loan_ids_140_diff, :received_on => Date.new(2012, 03, 21)).each do |p|
        if p.type == :principal
          p.amount = 642
        elsif p.type == :interest
          p.amount = 108
        end
        p.save
      end
      #updating history of loans.
      loan_ids_140_diff.each do |l|
        loan = Loan.get(l)
        loan.update_history
      end

      #correcting payment for Rs.154 diff in payment.
      Payment.all(:loan_id => loan_ids_154_diff, :received_on => Date.new(2012, 03, 21)).each do |p|
        if p.type == :principal
          p.amount = 821
        elsif p.type == :interest
          p.amount = 179
        end
        p.save
      end
      #updating history of loans.
      loan_ids_154_diff.each do |l|
        loan = Loan.get(l)
        loan.update_history
      end

      #correcting payment for Rs.172 diff in payment.
      Payment.all(:loan_id => loan_ids_172_diff, :received_on => Date.new(2012, 03, 21)).each do |p|
        if p.type == :principal
          p.amount = 839
        elsif p.type == :interest
          p.amount = 161
        end
        p.save
      end
      #updating history of loans.
      loan_ids_172_diff.each do |l|
        loan = Loan.get(l)
        loan.update_history
      end

      #correcting payment for Rs.191 diff in payment.
      Payment.all(:loan_id => loan_ids_191_diff, :received_on => Date.new(2012, 03, 21)).each do |p|
        if p.type == :principal
          p.amount = 858
        elsif p.type == :interest
          p.amount = 142
        end
        p.save
      end
      #updating history of loans.
      loan_ids_191_diff.each do |l|
        loan = Loan.get(l)
        loan.update_history
      end

      #correcting payment for Rs.126 payment in exceptions.
      Payment.all(:loan_id => loan_ids_exceptions_diff, :received_on => Date.new(2012, 03, 21)).each do |p|
        if p.type == :principal
          p.amount = 628
        elsif p.type == :interest
          p.amount = 122
        end
        p.save
      end
      #updating history of loans.
      loan_ids_exceptions_diff.each do |l|
        loan = Loan.get(l)
        loan.update_history
      end
      t2 = Time.now
      puts "Time taken: #{t2-t1} seconds"
      puts "Payments have been rectified"
    end
  end
end
