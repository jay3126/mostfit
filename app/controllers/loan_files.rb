class LoanFiles < Application

  def index
    render :loan_file_generation
  end

  def get_loan_applications
    debugger
    @branch_id = params['branch_id'] ? params['branch_id'] : nil
    @center_id = params['center_id'] ? params['center_id'] : nil
    facade = LoanApplicationsFacade.new(session.user)
    @loan_applications_pending_loan_file_generation = facade.pending_loan_file_generation({:at_branch_id=>@branch_id})
     
    render :loan_file_generation
  end

  def loan_file_generation
    if request.method == :post
      loan_applications = params['selected'].keys
      laf = LoanApplicationFacade.new()
      if params['loan_file'] and not param['loan_file'].nil?
        loan_file = laf.get_loan_file(params['loan_file'])    
        laf.add_to_loan_file(on_loan_file, params['by_staff'], params['on_date'], *loan_applications)
      else
        loan_file = laf.create_loan_file(at_branch, at_center, for_cycle_number, by_staff, on_date, *loan_applications)
      end
    end
  end

end
