class StockRegisters < Application
  before :get_context, :exclude => ['redirect_to_show']
  provides :xml, :yaml, :js
  include DateParser

  def index
    if request.xhr? and params[:biz_location_id]
      @stock_registers = StockRegister.all(:biz_location_id => params[:biz_location_id]).paginate(:page => params[:page], :per_page => 15, :order => [:date_of_entry.desc])
      display @stock_registers, :layout => layout?
    else
      @stock_registers = (@stock_registers || StockRegister.all).paginate(:page => params[:page], :per_page => 15)
      display @stock_registers, :layout => layout?
    end
  end

  def show(id)
    @stock_register = StockRegister.get(id)
    raise NotFound unless @stock_register
    display @stock_register, :layout => layout?
  end

  def show_from_biz_location(id)
    @stock_register = StockRegister.get(id)
    raise NotFound unless @stock_register
    display @stock_register, :layout => layout?
  end

  def new
    only_provides :html
    @stock_register = StockRegister.new
    @branch = BizLocation.get(params[:biz_location_id]) if params and params.key?(:biz_location_id)
    display @stock_register, :layout => layout?
  end

  def edit(id)
    only_provides :html
    @stock_register = StockRegister.get(id)
    raise NotFound unless @stock_register
    @branch = @stock_register.biz_location if @stock_register.biz_location_id
    display @stock_register, :layout => layout?
  end

  def edit_from_biz_location(id)
    only_provides :html
    @stock_register = StockRegister.get(id)
    raise NotFound unless @stock_register
    @branch = @stock_register.biz_location if @stock_register.biz_location_id
    display @stock_register, :layout => layout?
  end

  def create
    stock_register = {:manager_staff_id => params[:manager_staff_id], :stock_quantity => params[:stock_quantity], :stock_code => params[:stock_code], :stock_name => params[:stock_name], :biz_location_id => params[:biz_location_id], :bill_number => params[:bill_number], :bill_date => params[:stock_register][:bill_date], :date_of_entry => params[:stock_register][:date_of_entry]}
    @stock_register = StockRegister.new(stock_register)
    if @stock_register.save
      redirect(params[:return] || url("user_locations/show/#{@stock_register.biz_location_id}"), :message => {:notice => "Stock entry was successfully entered"})
    else
      message[:error] = "Stock entry failed to be entered"
      render :new #error message will show
    end
  end

  def update(id, stock_register)
    @stock_register = StockRegister.get(id)
    raise NotFound unless @stock_register
    if @stock_register.update(stock_register)
      redirect(params[:return] || url("user_locations/show/#{@stock_register.biz_location_id}" + "#stock_register"), :message => {:notice => "Stock entry was successfully updated"})
    else
      display @stock_register, :edit 
    end
  end

  def destroy(id)
    @stock_register = StockRegister.get(id)
    raise NotFound unless @stock_register
    @biz_location_id = @stock_register.biz_location_id
    if @stock_register.destroy
      redirect(params[:return] || url("user_locations/show/#{@biz_location_id}" + "#stock_register"), :message => {:notice => "Stock entry was successfully deleted"})
    else
      raise InternalServerError
    end
  end

  def delete(id)
    edit(id)
  end

  def redirect_to_show(id)
    raise NotFound unless @stock_register = StockRegister.get(id)
    redirect resource(@stock_register)
  end

  private
  def get_context
    @branch = BizLocation.get(params[:biz_location_id]) if params.key?(:biz_location_id)
  end

end # StockRegisters
