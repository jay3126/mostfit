class FeeInstances < Application

  def index
  end

  def fee_instance_on_lending
    @lending = Lending.get params[:lending_id]
    @fee_lendings = FeeInstance.get_all_fees_for_instance(@lending)
    render :template => 'fee_instances/fee_instance_on_lending', :layout => layout?
  end
end