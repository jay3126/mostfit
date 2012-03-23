require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "List of duplicate clients"
  task :de_dupe_report do
    require 'fastercsv'

    duplicates = {}
    duplicates[:same_ration_card_number_clients]= []      #this array is to get duplicate clients.
    duplicates[:same_ration_card_number_loan_applicants]= []    #this array is to get duplicate loan_applicants.
    ration_card_is_nil_for_clients = []   #this array is to store all those clients whose ration_card is nil.
    ration_card_is_nil_for_loan_applications = []    #this array is to store all those loan_applicants whose ration card is nil.
    ration_card_numbers = {}    #main hash to compare for duplicates. Key is ration_card and value is either client or loan_appliant.

    #following are the hashes which is used to check for duplicate clients according to their various id_proofs. 
    id_proof_passport_client = {}
    id_proof_voter_id_client = {}
    id_proof_uid_client = {}
    id_proof_others_client = {}
    id_proof_driving_licence_client = {}
    id_proof_pan_client = {}
    id_proof_is_nil_for_clients = []   #this array is to store those clients whose id_proofs are nil.

    #following are the arrays which are used to store duplicate clients according to their various id_proofs.
    duplicates[:same_id_proof_passport_clients] = []
    duplicates[:same_id_proof_voter_id_clients] = []
    duplicates[:same_id_proof_uid_clients] = []
    duplicates[:same_id_proof_others_clients] = []
    duplicates[:same_id_proof_pan_clients] = []
    duplicates[:same_id_proof_driving_licence_clients] = []

    id_proof_is_nil_for_loan_applicants = [] #this array is to store loan_applicants whose id_proofs are nil.

    #following are the hashes which is used to check for duplicate loan_appliants according to their various id_proofs.
    id_proof_passport_loan_applicant = {}
    id_proof_voter_id_loan_applicant = {}
    id_proof_uid_loan_applicant = {}
    id_proof_others_loan_applicant = {}
    id_proof_driving_licence_loan_applicant = {}
    id_proof_pan_loan_applicant = {}

    #following are the arrays which are used to store duplicate loan_applicants according to their various id_proofs.
    duplicates[:same_id_proof_passport_loan_applicants] = []
    duplicates[:same_id_proof_voter_id_loan_applicants] = []
    duplicates[:same_id_proof_uid_loan_applicants] = []
    duplicates[:same_id_proof_others_loan_applicants] = []
    duplicates[:same_id_proof_pan_loan_applicants] = []
    duplicates[:same_id_proof_driving_licence_loan_applicants] = []

    clients = Client.all(:fields => [:id, :name, :reference]).map{|cl| [cl.id, cl]}.to_hash
    loan_applicants = LoanApplication.all(:fields => [:id, :client_id, :client_name, :client_reference1]).map{|la| [la.id, la]}.to_hash

    #checking for duplicate clients handling both the conditions, i.e., ration_card and various id_proofs.
    clients.each do |cid, client|

      #handling the case when ration_card and id_proofs are nil.
      if client.reference.nil?
        ration_card_is_nil_for_clients.push(client)
      elsif client.reference2.nil?
        id_proof_is_nil_for_clients.push(client)

      #checking for dupliates start here.
      elsif client.reference and client.reference.length>0
        if ration_card_numbers.key?(client.reference)
          duplicates[:same_ration_card_number_clients].push([client, ration_card_numbers[client.reference]])
        else
          ration_card_numbers[client.reference] = client
        end

      elsif (client.reference2 and client.reference2_type and (client.reference2_type == ("Passport")) and client.reference2.length>0)
        if id_proof_passport_client.key?(client.reference2)
          duplicates[:same_id_proof_passport_clients].push([client, id_proof_passport_client[client.reference2]])
        else
          id_proof_passport_client[client.reference2] = client
        end

      elsif (client.reference2 and client.reference2_type and (client.reference2_type == "Voter Id") and client.reference2.length>0)
        if id_proof_voter_id_client.key?(client.reference2)
          duplicates[:same_id_proof_voter_id_clients].push([client, id_proof_voter_id_client[client.reference2]])
        else
          id_proof_voter_id_client[client.reference2] = client
        end

      elsif (client.reference2 and client.reference2_type and (client.reference2_type == "UID") and client.reference2.length>0)
        if id_proof_uid_client.key?(client.reference2)
          duplicates[:same_id_proof_uid_clients].push([client, id_proof_uid_client[client.reference2]])
        else
          id_proof_uid_client[client.reference2] = client
        end

      elsif (client.reference2 and client.reference2_type and (client.reference2_type == "Others") and client.reference2.length>0)
        if id_proof_others_client.key?(client.reference2)
          duplicates[:same_id_proof_others_clients].push([client, id_proof_others_client[client.reference2]])
        else
          id_proof_others_client[client.reference2] = client
        end

      elsif (client.reference2 and client.reference2_type and (client.reference2_type == "Driving Licence No") and client.reference2.length2>0)
        if id_proof_driving_licence_client.key?(client.reference2)
          duplicates[:same_id_proof_driving_licence_clients].push([client, id_proof_driving_licence_client[client.reference2]])
        else
          id_proof_driving_licence_client[client.reference2] = client
        end

      elsif (client.reference2 and client.reference2_type and (client.reference2_type == "PAN") and client.reference2.length>0)
        if id_proof_pan_client.key?(client.reference2)
          duplicates[:same_id_proof_pan_clients].push([client, id_proof_pan_client[client.reference2]])
        else
          id_proof_pan_client[client.reference2] = client
        end
      end
    end

    #checking for duplicate loan_applicants handing both the conditions, i.e, ration_card and varous id_proofs.
    loan_applicants.each do |laid, applicant|

      #handling conditions where the ration_card and id_proof are nil.
      if applicant.client_reference1.nil?
        ration_card_is_nil_for_loan_applications.push(applicant)
      elsif applicant.client_reference2.nil?
        id_proof_is_nil_for_loan_applicants.push(applicant)

      #checking for duplications start here inside the loop.
      elsif (applicant.client_reference1 and applicant.client_reference1.length>0)
        if ration_card_numbers.key?(applicant.client_reference1)
          duplicates[:same_ration_card_number_loan_applicants].push([applicant, ration_card_numbers[applicant.client_reference1]])
        else
          ration_card_numbers[applicant.client_reference1] = applicant
        end

      elsif (applicant.client_reference2 and applicant.client_reference2_type and (applicant.client_reference2_type == "Passport") and applicant.client_reference2.length>0)
        if id_proof_passport_loan_applicant.key?(applicant.client_reference2)
          duplicates[:same_id_proof_passport_loan_applicants].push([applicant, id_proof_passport_loan_applicant[applicant.client_reference2]])
        else
          id_proof_passport_loan_applicant[applicant.client_reference2] = applicant
        end

      elsif (applicant.client_reference2 and applicant.client_reference2_type and (applicant.client_reference2_type == "Voter Id") and applicant.client_reference2.length>0)
        if id_proof_voter_id_loan_applicant.key?(applicant.client_reference2)
          duplicates[:same_id_proof_voter_id_loan_applicants].push([applicant, id_proof_voter_id_loan_applicant[applicant.client_reference2]])
        else
          id_proof_voter_id_loan_applicant[applicant.client_reference2] = applicant
        end

      elsif (applicant.client_reference2 and applicant.client_reference2_type and (applicant.client_reference2_type == "UID") and applicant.client_reference2.length>0)
        if id_proof_uid_loan_applicant.key?(applicant.client_reference2)
          duplicates[:same_id_proof_uid_loan_applicants].push([applicant, id_proof_uid_loan_applicant[applicant.client_reference2]])
        else
          id_proof_uid_loan_applicant[applicant.client_reference2] = applicant
        end

      elsif (applicant.client_reference2 and applicant.client_reference2_type and (applicant.client_reference2_type == "Others") and applicant.client_reference2.length>0)
        if id_proof_others_loan_applicant.key?(applicant.client_reference2)
          duplicates[:same_id_proof_others_loan_applicants].push([applicant, id_proof_others_loan_applicant[applicant.client_reference2]])
        else
          id_proof_others_loan_applicant[applicant.client_reference2] = applicant
        end

      elsif (applicant.client_reference2 and applicant.client_reference2_type and (applicant.client_reference2_type == "Driving Licence No") and applicant.client_reference2.length>0)
        if id_proof_driving_licence_loan_applicant.key?(applicant.client_reference2)
          duplicates[:same_id_proof_driving_licence_loan_applicants].push([applicant, id_proof_driving_licence_loan_applicant[applicant.client_reference2]])
        else
          id_proof_driving_licence_loan_applicant[applicant.client_reference2] = applicant
        end

      elsif (applicant.client_reference2 and applicant.client_reference2_type and (applicant.client_reference2_type == "Pan") and applicant.client_applicant2.length>0)
        if id_proof_pan_loan_applicant.key?(applicant.client_reference2)
          duplicates[:same_id_proof_pan_loan_applicants].push([applicant, id_proof_pan_loan_applicant[applicant.client_reference2]])
        else
          id_proof_pan_loan_applicant[applicant.client_reference2] = applicant
        end

      end
    end

    #getting the list on a file in csv format in 2 different files. One is for clients and the other is for loan_applicants.
    begin
      clients_out_file_path = File.join(Merb.root, "/tmp/duplicate_clients_report.clients.#{DateTime.now.to_s}.csv")
      FasterCSV.open(clients_out_file_path, "w", :force_quotes => true) do |results_csv|

        client_rows1 = duplicates[:same_ration_card_number_clients]
        results_csv << "Same Ration Card Number clients"
        client_rows1.each { |row1|
          client1 = row1.first
          ration_card_number = client1.reference
          results_csv << [client1.id, client1.name, ration_card_number]
        }

        client_rows2 = duplicates[:same_id_proof_passport_clients]
        results_csv << "Same ID Proof - Passport clients"
        client_rows2.each {|row2|
          client2 = row2.first
          id_proof_passport = client2.reference2
          results_csv << [client2.id, client2.name, id_proof_passport]
        }

        client_rows3 = duplicates[:same_id_proof_voter_id_clients]
        results_csv << "Same ID Proof - Voter Id clients"
        client_rows3.each {|row3|
          client3 = row3.first
          id_proof_voter_id = client3.reference2
          results_csv << [client3.id, client3.name, id_proof_voter_id]
        }

        client_row4 = duplicates[:same_id_proof_uid_clients]
        results_csv << "Same ID Proof - UID clients"
        client_rows4.each {|row4|
          client4 = row4.first
          id_proof_uid = client4.reference2
          results_csv << [client4.id, client4.name, id_proof_uid]
        }

        client_row5 = duplicates[:same_id_proof_others_clients]
        results_csv << "Same ID Proof - Others clients"
        client_row5.each {|row5|
          client5 = row5.first
          id_proof_others = client5.reference2
          results_csv << [client5.id, client5.name, id_proof_others]
        }

        client_row6 = duplicates[:same_id_proof_driving_licence_clients]
        results_row << "Same ID Proof - Driving Licence clients"
        client_row6.each {|row6|
          client6 = row6.first
          id_proof_driving_licence = client6.reference2
          results_csv << [client6.id, client6.name, id_proof_driving_licence]
        }

        client_row7 = duplicates[:same_id_proof_pan_clients]
        results_row << "Same ID Proof - Pan clients"
        client_row7.each {|row7|
          client7 = row7.first
          id_proof_pan = client7.reference2
          results_csv << [client7.id, client7.name, id_proof_pan]
        }
      end

      loan_applicants_out_file_path = File.join(Merb.root, "/tmp/duplicate_clients_report.loan_applicants.#{DateTime.now.to_s}.csv")
      FasterCSV.open(loan_applicants_out_file_path, "w", :force_quotes => true) do |results1_csv|

        loan_applicant_rows1 = duplicates[:same_ration_card_number_loan_applicants]
        results1_csv << "Same Ration Card Number Loan Applicants"
        loan_applicant_rows1.each { |row1|
          loan_applicant1 = row1.first
          ration_card_number = loan_applicant1.client_reference1
          loan_applicant_name = (loan_applicant1 and loan_applicant1.respond_to?(:client_name)) ? loan_applicant1.client_name : "-"
          results1_csv << [loan_applicant1.id, loan_applicant_name, ration_card_number]
        }

        loan_applicant_rows2 = duplicates[:same_id_proof_passport_loan_applicants]
        results1_csv << "Same ID Proof - Passport Loan Applicants"
        loan_applicant_rows2.each { |row2|
          loan_applicant2 = row2.first
          id_proof_passport = loan_applicant2.client_reference2
          loan_applicant_name = (loan_applicant2 and loan_applicant2.respond_to?(:client_name)) ? loan_applicant2.client_name : "-"
          results1_csv << [loan_applicant2.id, loan_applicant_name, id_proof_passport]
        }

        loan_applicant_rows3 = duplicates[:same_id_proof_voter_id_loan_applicants]
        results1_csv << "Same ID Proof - Voter Id Loan Applicants"
        loan_applicant_rows3.each { |row3|
          loan_applicant3 = row3.first
          id_proof_voter_id = loan_applicant3.client_reference2
          loan_applicant_name = (loan_applicant3 and loan_applicant3.respond_to?(:client_name)) ? loan_applicant3.client_name : "-"
          results1_csv << [loan_applicant3.id, loan_applicant_name, id_proof_voter_id]
        }

        loan_applicant_rows4 = duplicates[:same_id_proof_uid_loan_applicants]
        results1_csv << "Same ID Proof - UID Loan Applicants"
        loan_applicant_rows4.each { |row4|
          loan_applicant4 = row4.first
          id_proof_voter_id = loan_applicant4.client_reference2
          loan_applicant_name = (loan_applicant4 and loan_applicant4.respond_to?(:client_name)) ? loan_applicant4.client_name : "-"
          results1_csv << [loan_applicant4.id, loan_applicant_name, id_proof_voter_id]
        }

        loan_applicant_rows5 = duplicates[:same_id_proof_others_loan_applicants]
        results1_csv << "Same ID Proof - Others Loan Applicants"
        loan_applicant_rows5.each { |row5|
          loan_applicant5 = row5.first
          id_proof_voter_id = loan_applicant5.client_reference2
          loan_applicant_name = (loan_applicant5 and loan_applicant5.respond_to?(:client_name)) ? loan_applicant5.client_name : "-"
          results1_csv << [loan_applicant5.id, loan_applicant_name, id_proof_voter_id]
        }

        loan_applicant_rows6 = duplicates[:same_id_proof_driving_licence_loan_applicants]
        results1_csv << "Same ID Proof - Driving Licence Loan Applicants"
        loan_applicant_rows6.each { |row6|
          loan_applicant6 = row6.first
          id_proof_voter_id = loan_applicant6.client_reference2
          loan_applicant_name = (loan_applicant6 and loan_applicant6.respond_to?(:client_name)) ? loan_applicant6.client_name : "-"
          results1_csv << [loan_applicant6.id, loan_applicant_name, id_proof_voter_id]
        }

        loan_applicant_rows7 = duplicates[:same_id_proof_pan_loan_applicants]
        results1_csv << "Same ID Proof - Pan Loan Applicants"
        loan_applicant_rows7.each { |row7|
          loan_applicant7 = row7.first
          id_proof_voter_id = loan_applicant7.client_reference2
          loan_applicant_name = (loan_applicant7 and loan_applicant7.respond_to?(:client_name)) ? loan_applicant7.client_name : "-"
          results1_csv << [loan_applicant7.id, loan_applicant_name, id_proof_voter_id]
        }
        
      end
    rescue
    end
          
  end
end
