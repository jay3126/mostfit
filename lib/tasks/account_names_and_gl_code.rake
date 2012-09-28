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
  namespace :accounting do
    desc "This rake task generates the Name and GL code for all accounts"
    task :list_account_name_and_gl_code do
      sl_no = 0   #this variable is for serial number.
      f = File.open("tmp/account_name_with_gl_code_#{DateTime.now.to_s}.csv", "w")
      f.puts("\"Sl. No.\", \"Account Name\", \"GL Code\", \"Branch Id\", \"Branch Name\", \"Account Type\"")

      Account.all.each do |acc|
        sl_no += 1
        account_name = (acc and acc.name) ? acc.name : "Not Specified"
        account_gl_code = (acc and acc.gl_code) ? acc.gl_code : "Not Specified"
        branch_id = (acc and acc.branch_id) ? acc.branch_id : "Not attached to any branch"
        branch_name = (acc and acc.branch_id) ? acc.branch.name : "Not attached to any branch"
        account_type = (acc and acc.account_type_id) ? acc.account_type.name : "Not Specified"

        f.puts("#{sl_no}, \"#{account_name}\", \"#{account_gl_code}\", #{branch_id}, \"#{branch_name}\", \"#{account_type}\"")
      end
      f.close
    end

    desc "This will add ICash name to existing Accounts name and GL code"
    task :add_ICash_name_to_accounts_name_and_gl_code do
      Account.all.each do |acc|
        acc.name = "ICash-" + acc.name
        acc.gl_code = "ICash-" + acc.gl_code
        acc.save
      end
    end

    desc "This will rename Kotak to AVIVA"
    task :change_kotak_to_AVIVA do
      sl_no = 0   #this variable is for serial number.
      f = File.open("tmp/name_change_from_Kotak_to_AVIVA_#{DateTime.now.to_s}.csv", "w")
      f.puts("\"Sl. No.\", \"Account Name Before Renaming\", \"GL Code before renaming\", \"Account Name after Renaming\", \"GL Code after renaming\", \"Branch Id\", \"Branch Name\", \"Account Type\"")
      
      Account.all.each do |acc|
        next unless (acc.name.include?("Kotak") and acc.gl_code.include?("Kotak"))
        sl_no += 1
        old_acc_name = acc.name
        old_acc_gl_code = acc.gl_code
        acc.name = acc.name.gsub("Kotak", "AVIVA")
        new_acc_name = acc.name
        acc.gl_code = acc.gl_code.gsub("Kotak", "AVIVA")
        new_acc_gl_code = acc.gl_code
        acc.save

        f.puts("#{sl_no}, \"#{old_acc_name}\", \"#{old_acc_gl_code}\", \"#{new_acc_name}\", \"#{new_acc_gl_code}\", #{acc.branch_id}, \"#{acc.branch.name}\", \"#{acc.account_type.name}\"")
      end
      f.close
    end

  end
end
