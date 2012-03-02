class LoanApplications < Application
  # provides :xml, :yaml, :js

  def bulk_new
    if params[:method] == :post
      redirect 'data_entry/index'
    else
      render
    end
  end

end # LoanApplications
