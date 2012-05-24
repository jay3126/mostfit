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
            fastercsv << ["Quarter", "No of Loans", "Total Principal Outstanding", "Total Interest Outstanding", "Total Amount Outstanding", "Principal without Overdues"]
          end
          dates = []
          next_quarter_date = date_as_on
          while (next_quarter_date < (date_as_on + 365)) do
            dates << next_quarter_date
            next_quarter_date = (next_quarter_date + 28)
          end
          
          dates.each_with_index do |date, idx|
            loan_ids = LoanHistory.all(:date.gte => dates[idx], :date.lte => dates[idx+1], :status => :outstanding).aggregate(:loan_id)
            unless loan_ids.blank?
              row = LoanHistory.latest({:loan_id => loan_ids}, dates[idx+1]).aggregate(:loan_id.count, :actual_outstanding_principal.sum, :actual_outstanding_interest.sum, :actual_outstanding_total.sum)
              row.unshift("#{dates[idx]} to #{dates[idx+1]}")
              FasterCSV.open(filename, "a") do |fastercsv|
                fastercsv << row
              end
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
