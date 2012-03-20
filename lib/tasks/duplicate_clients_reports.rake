require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "List of duplicate clients"
  task :de_dupe_report do
    require 'fastercsv'

    duplicates = Hash.new()
    duplicates[:same_ration_card_number_clients]= []      #this array is to get duplicate clients.
    duplicates[:same_ration_card_number_loan_applicants]= []    #this array is to get duplicate loan_applicants.
    ration_card_is_nil_for_clients = []   #this array is to store all those clients whose ration_card is nil.
    ration_card_is_nil_for_loan_applications = []    #this array is to store all those loan_applicants whose ration card is nil.
    ration_card_numbers = {}    #main hash to compare for duplicates. Key is ration_card and value is either client or loan_appliant.

    clients = Client.all(:fields => [:id, :name, :reference]).map{|cl| [cl.id, cl]}.to_hash
    loan_applicants = LoanApplication.all(:fields => [:id, :client_id, :client_name, :client_reference1]).map{|la| [la.id, la]}.to_hash

    clients.each do |cid, client|
      if client.reference.nil?
        ration_card_is_nil_for_clients.push(client)
      else
        if client.reference and client.reference.length>0
          if ration_card_numbers.key?(client.reference)
            duplicates[:same_ration_card_number_clients].push([client, ration_card_numbers[client.reference]])
          else
            ration_card_numbers[client.reference] = client
          end
        end
      end
    end

    loan_applicants.each do |laid, applicant|
      if applicant.client_reference1.nil?
        ration_card_is_nil_for_loan_applications.push(applicant)
      else
        if applicant.client_reference1 and applicant.client_reference1.length>0
          if ration_card_numbers.key?(applicant.client_reference1)
            duplicates[:same_ration_card_number_loan_applicants].push([applicant, ration_card_numbers[applicant.client_reference1]])
          else
            ration_card_numbers[applicant.client_reference1] = applicant
          end
        end
      end
    end

    begin
      out_file_path = File.join(Merb.root, "/tmp/duplicate_clients_report(clients).#{DateTime.now.to_s}.csv")
      FasterCSV.open(out_file_path, "w", :force_quotes => true) do |results_csv|
        duplicates.each{ |reason, rows|
          results_csv << [reason]
          rows.each { |dup|
            client = dup.first
            results_csv << [client.id, client.name, client.reference]
          }
        }
      end

      out_file_path = File.join(Merb.root, "/tmp/duplicate_clients_report(loan_applicants).#{DateTime.now.to_s}.csv")
      FasterCSV.open(out_file_path, "w", :force_quotes => true) do |results_csv|
        duplicates.each{ |reason, rows|
          results_csv << [reason]
          rows.each { |dup|
            applicant = dup.first
            results_csv << [applicant.id, applicant.client_name, applicant.client_reference1]
          }
        }
      end
    rescue
    end
          
  end
end
