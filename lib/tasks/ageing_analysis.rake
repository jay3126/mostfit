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
  namespace :reports do
    desc "Ageing analysis for a year"
    task :ageing_analysis, :date do |t, args|
      USAGE = <<USAGE_TEXT
         USAGE: rake mostfit:reports:ifmr[<as_on_date>]
        
         NOTE: The format for the date is DD-MM-YYYY. The date has to be enclosed in single quotes. For 6th August 2011 it shall be '06-08-2011'.
        
         EXAMPLE: rake mostfit:reports:ageing_analysis['06-07-2011']
USAGE_TEXT

      begin
        if args[:date].blank?
          date_as_on = nil
        else
          date_as_on = Date.parse(args[:date])
        end
        
        if !(date_as_on.is_a?(Date))
          puts USAGE
        else
          folder = File.join(Merb.root, "docs", "reports")
          FileUtils.mkdir_p(folder)
          filename = File.join(folder, "ageing_analysis_as_on_#{date_as_on}_generated_at_#{DateTime.now.ctime.gsub(" ", "_")}.csv")
          FasterCSV.open(filename, "w") do |fastercsv|
            fastercsv << ["Balance tenure", "No of Loans", "Total Principal Outstanding", "Expected Principal Collections", "No of Loans not Overdue", "Principal outstanding of loans not overdue", "Expected principal collections of loans not overdue"]
          end
          dates = []
          next_quarter_date = date_as_on
          # generating an array of dates spaced apart quarterly beginning from the given date
          while (next_quarter_date < (date_as_on + 365)) do
            dates << next_quarter_date
            next_quarter_date = (next_quarter_date + 28) #calculating the date of the next quarter
          end
          
          dates.each_with_index do |date, idx|
            row = []            
            if (idx == 0) # for the first quarter
              row << "till #{dates[idx+1] - 1}"
              query = {:date.lt => dates[idx+1], :status => :outstanding}
            elsif (idx == (dates.count - 1)) # for the last quarter
              row << "#{dates[idx]} onwards"
              query = {:date.gte => dates[idx], :status => :outstanding}
            else
              row << "#{dates[idx]} to #{dates[idx+1] - 1}" # for all the inbetween quarters
              query = {:date.gte => dates[idx], :date.lt => dates[idx+1], :status => :outstanding} 
            end
            loan_ids_outstanding_for_a_period = LoanHistory.all(query).aggregate(:loan_id)
            loan_ids_disbursed_after_as_on_date = Loan.all(:disbursal_date.gte => date_as_on).aggregate(:id)
            loan_ids = loan_ids_outstanding_for_a_period - loan_ids_disbursed_after_as_on_date
            query_next = query
            status_hash = STATUSES.each_with_index.map{|x, index| [x,index+1]}.to_hash
            query_next[:status] = status_hash[query[:status]]
            not_overdue_loan_ids_for_a_period = LoanHistory.loan_ids_not_overdue(query_next)
            not_overdue_loan_ids = not_overdue_loan_ids_for_a_period - loan_ids_disbursed_after_as_on_date

            unless loan_ids.blank?
              entry = []
              entry += LoanHistory.latest({:loan_id => loan_ids}, dates[idx]).aggregate(:loan_id.count, :scheduled_outstanding_principal.sum)
              entry << LoanHistory.all(:loan_id => loan_ids, :date.gte => dates[idx], :date.lt => dates[idx+1]).aggregate(:scheduled_principal_due.sum)
              row += entry
            else 
              row += [0,0,0]
            end

            unless not_overdue_loan_ids.blank?
              entry = []
              entry += LoanHistory.latest({:loan_id => not_overdue_loan_ids}, dates[idx]).aggregate(:loan_id.count, :scheduled_outstanding_principal.sum)
              entry << LoanHistory.all(:loan_id => not_overdue_loan_ids, :date.gte => dates[idx], :date.lt => dates[idx+1]).aggregate(:scheduled_principal_due.sum)
              row += entry
            else
              row += [0,0,0]
            end

            FasterCSV.open(filename, "a") do |fastercsv|
              fastercsv << row
            end
          end
        end
      rescue => error
        puts "An exception occured: #{error}"
        puts USAGE
      end
    end
  end
end
