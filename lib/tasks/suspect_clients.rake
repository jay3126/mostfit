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
  namespace :dedupe do
    desc "attempts to identify potentially suspicious client accounts that might be the same person"
    task :suspicious_clients do |t, args|
      require 'fastercsv'

      USAGE = <<USAGE_TEXT
[bin/]rake mostfit:dedupe:suspicious_clients
Runs on all client accounts and generates an output that lists potentially duplicate client accounts
USAGE_TEXT

      begin

        dcr = DuplicateClientsReport.new

        data = [] #account number can be nil, others cannot be
        soundex_names, soundex_spouse_names, account_numbers = {}, {}, {}
        duplicates = Hash.new() #this one stores info like name, center_name, branch_name etc. hashed by ID
        duplicates[:same_name_and_dob]        = []
        duplicates[:same_spouse_name_and_dob] = []
        #duplicates[:same_account_number]      = []

        clients = Client.all(:fields => [:id, :name, :spouse_name, :date_of_birth]).map{|cl| [cl.id, cl]}.to_hash

        clients.each do |cid, client|
          #duplicate first name
          firstchar, name_rest    = dcr.soundex3(client.name)

          soundex_names[firstchar] ||= []
          soundex_names[firstchar].each{|other_client|
            if other_client[:rest] == name_rest and client.date_of_birth and client.date_of_birth == other_client[:client].date_of_birth
              duplicates[:same_name_and_dob].push([client, other_client[:client]])
            end
          }
          soundex_names[firstchar].push({:client => client, :rest => name_rest})

          #duplicate spouse name
          if client.spouse_name and not client.spouse_name.blank?
            firstchar, spouse_name_rest = dcr.soundex3(client.spouse_name)

            soundex_spouse_names[firstchar] ||= []
            soundex_spouse_names[firstchar].each_with_index{|other_client, idx|
              if other_client[:rest] == spouse_name_rest and client.date_of_birth == other_client[:client].date_of_birth and client.date_of_birth
                duplicates[:same_spouse_name_and_dob].push([client, other_client[:client]])
              end
            }
            soundex_spouse_names[firstchar].push({:client => client, :rest => spouse_name_rest})
          end

          #duplicate account number
          #      if client.account_number and client.account_number.length>0 and client.account_number.to_i>0
          #        puts client.id
          #        if account_numbers.key?(client.account_number)
          #          duplicates[:same_account_number].push([client, account_numbers[client.account_number]])
          #        else
          #          account_numbers[client.account_number] = client
          #        end
          #      end
        end

        out_file_path = File.join(Merb.root, "duplicate_clients.#{Date.today}.csv")
        FasterCSV.open(out_file_path, "w", :force_quotes => true) do |results_csv|
          duplicates.each { |reason, rows|
            results_csv << [reason]
            rows.each { |clients_ary|
              match, matched = clients_ary.first, clients_ary.last
              results_csv << [match.id, match.name, match.date_of_birth, match.spouse_name,
                matched.id, matched.name, matched.date_of_birth, matched.spouse_name]
            }
          }
        end
      rescue => ex
        puts "#{ex}"
        puts USAGE
        raise ex
      end
      
    end
  end
end