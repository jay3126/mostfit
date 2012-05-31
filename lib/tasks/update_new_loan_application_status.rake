require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end
Merb.start_environment(:environment => ENV['MERB_ENV'] || 'production')

namespace :mostfit do
  desc "Update New Loan Application Status"
  task :update_loan_application_status do
    require 'fastercsv'

    clients = Client.all(:fields => [:id, :name, :reference])
    loan_applicants = LoanApplicationsFacade.pending_dedupe
    total_loan_applications = LoanApplication.all - loan_applicants

    #checking for duplicate loan_applicants handing both the conditions, i.e, ration_card and varous id_proofs.
    loan_applicants.each do |applicant|
      loan_applicant_duplicate = false
      if applicant.client_id && clients.map(&:id).include?(applicant.client_id)
        LoanApplicationsFacade.new(User.first).not_duplicate(applicant.id)
        next
      end

      #handling conditions where the ration_card and id_proof are nil.
      if applicant.client_reference1.nil?
        loan_applicant_duplicate = true
      elsif applicant.client_reference2.nil?
        loan_applicant_duplicate = true

        #checking for duplications start here inside the loop.rake mostfit:update_loan_application_status
      elsif (applicant.client_reference1 and applicant.client_reference1.length>0)
        #checking reference1 in existing loan applications
        same_reference_clients = total_loan_applications.select{|la| la.client_reference1_type == applicant.client_reference1_type and la.client_reference1 == applicant.client_reference1}
        #checking reference1 in existing clients
        same_client_reference = clients.select{|c| (c.reference_type == applicant.client_reference1_type and c.reference == applicant.client_reference1) || (c.reference2_type == applicant.client_reference1_type and c.reference2 == applicant.client_reference1) }

        loan_applicant_duplicate = true unless same_reference_clients.blank? && same_client_reference.blank?
      end

      if (applicant.client_reference2 and applicant.client_reference2.length>0)
        #checking reference2 in existing loan applications.
        same_reference_clients = total_loan_applications.select{|la| la.client_reference2_type == applicant.client_reference2_type and la.client_reference2 == applicant.client_reference2}
        #checking reference2 in existing clients
        same_client_reference = clients.select{|c| (c.reference_type == applicant.client_reference2_type and c.reference == applicant.client_reference2) || (c.reference2_type == applicant.client_reference2_type and c.reference2 == applicant.client_reference2) }

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
