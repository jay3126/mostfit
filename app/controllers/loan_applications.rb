class LoanApplications < Application
  # provides :xml, :yaml, :js

  def bulk_new
    if request.method == :post
      redirect 'loan_applications/index'
    else
      render
    end
  end
  
  def list
    @center = Center.get(params[:center_id].to_i)
    raise NotFound unless @center
    @clients = @center.clients
    render :bulk_new
  end


end # LoanApplications
