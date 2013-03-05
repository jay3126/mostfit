require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "Update New Loan Application Status"
  task :dedupe do
    require 'fastercsv'

    
    loan_applicants         = LoanApplicationsFacade.pending_dedupe
    not_eligible_status     = Constants::Status::CPV_STATUSES - [Constants::Status::CPV2_APPROVED_STATUS] + [Constants::Status::NEW_STATUS]
    total_loan_applications = LoanApplication.all(:status.not => not_eligible_status) - loan_applicants
    all_clients             = loan_applicants.blank? ? [] : Client.all(:state.like => loan_applicants.map(&:client_state), :fields => [:id, :name,:reference_type, :reference,:reference2_type, :reference2])
    #checking for duplicate loan_applicants handing both the conditions, i.e, ration_card and varous id_proofs.
    loan_applicants.each do |applicant|
      loan_applicant_duplicate = false
      clients = all_clients.select{|c| c.state.downcase == applicant.client_state.downcase}
      if applicant.client_id && clients.map(&:id).include?(applicant.client_id)
        LoanApplicationsFacade.new(User.first).not_duplicate(applicant.id)
        next
      end

      #handling conditions where the ration_card and id_proof are nil.
      if applicant.client_reference1.blank? && applicant.client_reference2.blank?
        loan_applicant_duplicate = true

        #checking for duplications start here inside the loop.rake mostfit:update_loan_application_status
      elsif (applicant.client_reference1 and applicant.client_reference1.length>0)
        #checking reference1 in existing loan applications
        same_reference_clients = total_loan_applications.select{|la|
          la.client_reference1_type == applicant.client_reference1_type and !la.client_reference1.blank? && !applicant.client_reference1.blank? && la.client_reference1.downcase.strip == applicant.client_reference1.downcase.strip}
        #checking reference1 in existing clients
        same_client_reference = clients.select{|c| (c.reference_type == applicant.client_reference1_type and c.reference.downcase.strip.include?(applicant.client_reference1.downcase.strip)) || (c.reference2_type == applicant.client_reference1_type and c.reference2.downcase.strip.include?(applicant.client_reference1.downcase.strip)) }
        #checking reference1 in existing clients only for numeric reference1
        if same_client_reference.blank?
          reference1 = applicant.client_reference1.downcase.gsub(/[^0-9]/, '')
          same_client_reference = clients.select{|c| (c.reference_type == applicant.client_reference1_type and c.reference.downcase.strip.include?(reference1.strip)) || (c.reference2_type == applicant.client_reference1_type and c.reference2.downcase.strip.include(reference1.strip)) }
        end
        loan_applicant_duplicate = true if !same_reference_clients.blank? || !same_client_reference.blank?
      elsif (applicant.client_reference2 and applicant.client_reference2.length>0)
        #checking reference2 in existing loan applications.
        same_reference_clients = total_loan_applications.select{|la| la.client_reference2_type == applicant.client_reference2_type and la.client_reference2.downcase.strip == applicant.client_reference2.downcase.strip}
        #checking reference2 in existing clients
        same_client_reference = clients.select{|c| (c.reference_type == applicant.client_reference2_type and c.reference.downcase.strip.include?(applicant.client_reference2.downcase.strip)) || (c.reference2_type == applicant.client_reference2_type and c.reference2.downcase.strip.include?(applicant.client_reference2.downcase.strip)) }
        #checking reference1 in existing clients only for numeric reference2
        if same_client_reference.blank?
          reference2 = applicant.client_reference2.downcase.gsub(/[^0-9]/, '')
          same_client_reference = same_client_reference = clients.select{|c| (c.reference_type == applicant.client_reference2_type and c.reference.downcase.strip.include?(reference2.strip)) || (c.reference2_type == applicant.client_reference2_type and c.reference2.downcase.strip.include?(reference2.strip)) }
        end
        loan_applicant_duplicate = true unless same_reference_clients.blank? && same_client_reference.blank?
      end

      #Update loan application status suspected_duplicate or not_duplicate
      if loan_applicant_duplicate
        LoanApplicationsFacade.new(User.first).rate_suspected_duplicate(applicant.id)
      else
        LoanApplicationsFacade.new(User.first).not_duplicate(applicant.id)
      end
      total_loan_applications << applicant
    end
  end
end
