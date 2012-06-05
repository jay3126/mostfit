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
    desc "Generate the IFMR csv file"
    task :ifmr, :begin_date, :end_date do |t, args|
      USAGE = <<USAGE_TEXT
         USAGE: rake mostfit:reports:ifmr[<from_date>,<to_date>]
        
         NOTE: Make sure there are no spaces after and before the comma separating the two arguments. 
               The from_date has to be supplied. If the to_date is not supplied it is assumed to be today."
               The format for the date is DD-MM-YYYY. The date has to be enclosed in single quotes. For 6th August 2011 it shall be '06-08-2011'."
        
         EXAMPLE: rake mostfit:reports:ifmr['06-07-2011']"
                  rake mostfit:reports:ifmr['06-07-2011','13-07-2011']"
USAGE_TEXT

      begin
        if args[:begin_date].blank? or args[:end_date].blank?
          begin_date = nil
          end_date = nil
        else
          begin_date = Date.parse(args[:begin_date])
          end_date = Date.parse(args[:end_date])
        end

        if !(begin_date.is_a?(Date) and end_date.is_a?(Date))
          puts USAGE
        elsif end_date < begin_date
          puts "the end date given is less than the begin date"
        else
          folder = File.join(Merb.root, "docs", "reports")
          FileUtils.mkdir_p(folder)
          filename = File.join(folder, "ifmr_report_from_#{begin_date}_to_#{end_date}_generated_at_#{DateTime.now.ctime.gsub(" ", "_")}.csv")
          FasterCSV.open(filename, "w") do |fastercsv|
            fastercsv << ["Month", "Principal Preclosed", "Interest Preclosed", "No of Loans(Preclosure)", "Partial Principal Prepayment", "Partial Interest Prepayment", "No of Loans (Partial Prepayment)"]
          end
          dates = []
          next_month_date = begin_date
          while (next_month_date < end_date) do
            dates << next_month_date
            next_month_date = (next_month_date >> 1)
          end
          dates << end_date
          dates.uniq!
          dates.each_with_index do |date, idx|
            unless (dates.count == (idx + 1)) 
              row_preclosed = LoanHistory.all(:date.gte => dates[idx], :date.lt => dates[idx+1], :status => :preclosed, :last_status => :outstanding).aggregate(:advance_principal_paid_today.sum, :advance_interest_paid_today.sum, :loan_id.count)
              row_repaid = LoanHistory.all(:date.gte => dates[idx], :date.lt => dates[idx+1], :status => :repaid, :last_status => :outstanding, :scheduled_outstanding_principal.not => 0, :actual_outstanding_principal => 0).aggregate(:advance_principal_paid_today.sum, :advance_interest_paid_today.sum, :loan_id.count)
              row_prepayment = LoanHistory.all(:date.gte => dates[idx], :date.lt => dates[idx+1], :status => :outstanding, :total_advance_paid_today.not => 0).aggregate(:advance_principal_paid_today.sum, :advance_interest_paid_today.sum, :loan_id.count)
              row_preclosed.map!{|x| x = (x.nil? ? 0 : x)}
              row_repaid.map!{|x| x = (x.nil? ? 0 : x)}
              row_prepayment.map!{|x| x = (x.nil? ? 0 : x)}
              row = []
              row << row_preclosed[0] + row_repaid[0]
              row << row_preclosed[1] + row_repaid[1]
              row << row_preclosed[2] + row_repaid[2]
              row += row_prepayment
              row.unshift("#{date.month}/#{date.year}")
              FasterCSV.open(filename, "a") do |fastercsv|
                fastercsv << row
              end
            end
          end
        end
      rescue => error
        p "An exception occured: #{error}"
        p USAGE
      end
    end
  end
end