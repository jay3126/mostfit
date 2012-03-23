require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "Lists the attendances of clients"
  task :attendances do

    f = File.open("tmp/attendances_#{DateTime.now.to_s}.csv", "w")
    f.puts("\"Center Id\", \"Center Name\", \"Client Id\", \"Client Name\", \"Attendance Date\", \"Attendance Status\", \"Loan Id\", \"Loan Amount\", \"Loan Interest Rate\", \"Loan Disbursal Date\", \"Loan Product\", \"Number of Installments\", \"Installment Frequency\"")

    Attendance.all(:center_id => [107, 106, 124, 97, 198, 131, 130, 194]).each do |a|

      client = Client.get(a.client_id)

      loan = client.loans(:disbursal_date.gte => Date.new(2010, 12, 01), :disbursal_date.lte => Date.new(2011, 05, 15)).first

      if loan != nil
        loan_id = loan.id
        loan_disbursal_date = loan.disbursal_date
        loan_number_of_installments = loan.number_of_installments
        loan_product = loan.loan_product.name
        loan_amount = loan.amount
        loan_interest_rate = loan.interest_rate
        loan_installment_frequency = loan.installment_frequency.to_s
        
        client_id = client.id
        client_name = client.name

        date = a.date
        status = a.status

        center = Center.get(a.center_id)
        center_id = center.id
        center_name = center.name

        f.puts("#{center_id}, \"#{center_name}\", #{client_id}, \"#{client_name}\", #{date}, \"#{status}\", #{loan_id}, #{loan_amount}, #{loan_interest_rate}, #{loan_disbursal_date}, \"#{loan_product}\", #{loan_number_of_installments}, \"#{loan_installment_frequency}\"")
      end
    end
    f.close
  end
end
