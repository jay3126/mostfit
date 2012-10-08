class NewFundingLines < Application
  include DateParser

  def index
    @funding_lines = @funder.funding_lines
    display @funding_lines
  end

  def show(id)
    @funding_line = FundingLine.get(id)
    raise NotFound unless @funding_line
    display @funding_line
  end

  def new
    @funder = NewFunder.get(params[:new_funder_id])
    @funding_line = NewFundingLine.new
    display @funding_line
  end

  def create
    # INITIALIZING VARIABLES USED THROUGHOUT
    message = {}
    # GATE-KEEPING
    funder_id = params[:new_funder_id]
    amount_str = params[:amount]
    sanction_date = params[:new_funding_line][:sanction_date]
    begin
      @money = MoneyManager.get_money_instance(amount_str)
      amount = @money.amount
      currency = @money.currency
      @funder = NewFunder.get(funder_id)
      @funding_line = @funder.new_funding_lines.new({:amount => amount, :currency => currency, :new_funder_id => funder_id, :created_by => session.user.id, :sanction_date => sanction_date})
      message = {:notice => "Funding Line was successfully created"}
    rescue => ex
      message = {:error => ex.message}
    end
    if @funding_line.save
      redirect resource(:new_funders), :message => message
    else
      redirect url("new_funding_lines/new?#{funder_id}"), :message => {:error => "#{@funding_line.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
    end
  end

  def edit
    @funding_line = NewFundingLine.get(params[:id])
    @funder = @funding_line.new_funder
    raise NotFound unless @funding_line
    display @funding_line
  end

  def update(id, funding_line)
    funding_line[:interest_rate] = funding_line[:interest_rate].to_f / 100
    @funding_line = FundingLine.get(id)
    raise NotFound unless @funding_line
    @funder = Funder.get(params[:funder_id])
    if @funding_line.update_attributes(funding_line)
      redirect url("funders/#{@funder.id}/funding_lines/#{@funding_line.id}"), :message => {:notice => "Funding Line details updated successfully"}
    else
      redirect url("funders/#{@funder.id}/funding_lines/#{@funding_line.id}/edit"), :message => {:error => "Details of Funding Line cannot be updated because: #{@funding_line.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
    end
  end

end