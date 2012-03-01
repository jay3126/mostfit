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
  desc "This report gives report for Ananya Microfinance for Intellecash"
  task :ananya_report do
    branch_ids = [3]

    loan_ids = [13438,13448,13451,13453,13456,13463,13464,13465,13466,13467,13468,13469,13470,13471,13472,13473,13474,13475,13476,13477,13478,13479,13480,13481,13482,13483,13484,13485,13486,13487,13488,13489,13490,13491,13492,13493,13494,13495,13496,13497,13633,13634,13635,13636,13637,13638,13639,13640,13641,13642,13643,13644,13645,13646,13647,13648,13649,13650,13651,13652,13653,13654,13655,13656,13657,13658,13659,13660,13661,13662,13663,13664,13665,13666,13667,13668,13669,13670,13671,13672,13673,13674,13675,13676,13677,13678,13679,13680,13681,13682,13683,13684,13685,13686,13687,13688,13689,13690,13691,13692,13838,13839,13840,13841,13842,13843,13844,13845,13846,13847,13848,13849,13850,13851,13852,13853,13854,13855,13856,13857,13858,13859,13860,13861,13862,13863,13864,13865,13866,13867,13868,13869,13870,13871,13872,13873,13874,13875,13876,13877,13878,13879,13880,13881,13882,13948,13949,13950,13951,13952,13953,13954,13955,13956,13957,13963,13964,13968,13970,13972,13974,13975,13977,13979,13981,13993,13994,13995,13996,13997,14020,14023,14025,14027,14028,14029,14031,14033,14036,14039,14437,14440,14444,14445,14447,14448,14449,14451,14452,14453,14454,14455,14456,14457,14458,14459,14460,14461,14462,14463,14464,14465,14466,14467,14468,14469,14470,14471,14472,14473,14474,14475,14476,14477,14478,14479,14480,14481,14482,14483,14484,14485,14486,14487,14488,14489,14490,14491,14492,14493,14494,14495,14496,14497,14498,14499,14500,14501,14502,14503,14504,14505,14506,14507,14508,14509,14510,14511,14512,14513,14514,14515,14516,14517,14518,14519,14520,14521,14522,14523,14609,14610,14611,14612,14613,14614,14615,14616,14617,14618,14619,14620,14621,14622,14623,14624,14625,14626,14627,14628,14629,14630,14631,14632,14633,14634,14635,14636,14637,14638,14639,14640,14641,14642,14643,14644,14645,14646,14647,14648,14649,14650,14651]

    sl_no = 0   #this variable is for serial number.
    date = Date.new(2012, 02, 29)   #this date is to get the outstandings of loan.

    # f = File.open("tmp/ananya_report_#{DateTime.now.to_s}.csv", "w")
    # f.puts("\"Sl. No.\", \"Branch Id\", \"Branch Name\", \"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Spouse Name\", \"Guarantor Name\", \"Group\", \"Village\", \"State\", \"Loan Id\", \"Loan Amount\", \"Loan Purpose\", \"Disbursal Date\", \"Scheduled Outstanding Principal\", \"Scheduled Outstanding Interest\", \"Actual Outstanding Principal\", \"Actual Outstanding Interest\"")

    f = File.open("tmp/address_#{DateTime.now.to_s}.csv","w")
    f.puts("\"Address\"")

    Loan.all(:c_branch_id => branch_ids, :id => loan_ids).each do |l|

      sl_no += 1

      branch = Branch.get(l.c_branch_id)
      branch_id = branch.id
      branch_name = branch.name

      center = Center.get(l.c_center_id)
      center_id = center.id
      center_name = center.name

      client = Client.get(l.client_id)
      client_id = client.id
      client_name = client.name
      client_spouse_name = client.spouse_name
      client_guarantor_name = client.guarantors[0].name if client.guarantors[0]
      if client.client_group
        client_group = client.client_group.name
      else
        client_group = "Not attached to any group"
      end
      client_village = client.village.name if client.village
      client_state = "Bihar"
      client_address = client.address

      loan_id = l.id
      loan_amount = l.amount
      loan_purpose = l.occupation.name
      loan_disbursal_date = l.disbursal_date
      loan_scheduled_outstanding_principal = l.scheduled_outstanding_principal_on(date)
      loan_scheduled_outstanding_interest = l.scheduled_outstanding_interest_on(date)
      loan_actual_outstanding_principal = l.actual_outstanding_principal_on(date)
      loan_actual_outstanding_interest = l.actual_outstanding_interest_on(date)

      # f.puts("#{sl_no}, #{branch_id}, \"#{branch_name}\", #{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", \"#{client_spouse_name}\", \"#{client_guarantor_name}\", \"#{client_group}\", \"#{client_village}\", \"#{client_state}\", #{loan_id}, #{loan_amount}, \"#{loan_purpose}\", #{loan_disbursal_date}, #{loan_scheduled_outstanding_principal}, #{loan_scheduled_outstanding_interest}, #{loan_actual_outstanding_principal}, #{loan_actual_outstanding_interest}")

      f.puts("\"#{client_address}\"")
    end
    f.close
  end
end
