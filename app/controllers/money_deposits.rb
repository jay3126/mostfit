class MoneyDeposits < Application

  def index
    if request.method == :post
      @errors = "This feature is under development."
    end
    render :layout => layout?
  end
  
end
