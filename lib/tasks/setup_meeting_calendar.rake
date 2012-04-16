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
  namespace :daily do
    desc "given a list of loans and principal outstanding, calculates the expected and current pos and corrections needed to payments"
    task :setup_meeting_calendar, :on_date, :number_of_days do |t, args|
      require 'date'

      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:daily:setup_meeting_calendar[<'yyyy-mm-dd'>,<number_of_days>]
Creates or updates meetings on the specified date, or today if no date is specified
USAGE_TEXT

      begin
        on_date_str = args[:on_date]
        on_date = (on_date_str and (not (on_date_str.empty?))) ? Date.parse(on_date_str) : Date.today

        # The following restriction will most likely need to be lifted, but will be done so after further consideration
        raise ArgumentError, "Cannot setup meeting calendar for a past date" if on_date < Date.today

        number_of_days_str = args[:number_of_days]
        number_of_days = (number_of_days_str and (not (number_of_days_str.empty?))) ? number_of_days_str.to_i : 7

        admin_user = User.get(1)
        meeting_facade = MeetingFacade.new(admin_user)

        # First setup proposed meetings
        calendar_date = on_date
        1.upto(number_of_days) do |count|
          calendar_date += 1
          meeting_facade.setup_meeting_calendar(calendar_date)
        end

        # Confirm today's meetings
        # TBD

      rescue => ex
        puts "An error occurred: #{ex.message}"
        puts USAGE
      end
    end
  end
end
