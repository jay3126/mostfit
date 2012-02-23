# Add the local gems dir if found within the app root; any dependencies loaded
# hereafter will try to load from the local gems before loading system gems.
if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

require "merb-core"
require "fastercsv"

# this loads all plugins required in your init file so don't add them
# here again, Merb will do it for you
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'development')

namespace :mostfit do
  namespace :migration do
    desc "set the staff member for all data entry operators to nil"
    task :dissociate_staff_from_data_entry_user do |t, args|
      begin
        t1 = Time.now
        #users = User.all(:role => :data_entry)
        user_ids = User.all(:role => :data_entry).aggregate(:id)
        staff_members = StaffMember.all(:user_id => user_ids)
        folder = File.join(Merb.root, "docs", "rake_logs")
        mkdir_p(folder)
        status_file_path = File.join(folder, "dissocation_data_entry_staff_member_#{Time.now.strftime("%d_%m_%Y_%H_%M_%S")}.csv")
        HEADER = ["USER_ID", "LOGIN", "ROLE", "STAFF_MEMBER_LINKED", "STATUS_OF_DELINKING"]
        FasterCSV.open(status_file_path, "w") do |status_csv|
          status_csv << HEADER
        end
        errors = []
        staff_members.each do |staff_member|
          user = staff_member.user
          staff_member.user_id = nil
          status = staff_member.save!
          FasterCSV.open(status_file_path, "a") do |status_csv|
            status_csv << [staff_member.user_id, user.login, user.role, staff_member.name, status]
          end
          errors << staff_member.errors if status == false
        end
        # users.each do |user|
        #   unless user.staff_member.nil?
        #     staff_member = user.staff_member
        #     user.staff_member = nil 
        #     status = user.save
        #     FasterCSV.open(status_file_path, "a") do |status_csv|
        #       status_csv << [user.id, user.login, user.role, staff_member.name, status]
        #     end
        #     errors << user.errors if status == false
        #   end
        # end
        errors.each do |error|
          p error
        end
        t2 = Time.now
        puts "TIME TAKEN: #{t2-t1}"
      rescue => ex
        puts "ERROR ENCOUNTERED"
        puts ex
      end
    end
  end
end
