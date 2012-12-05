class NewFundingLines < Application
  include DateParser

  def index
    @funding_lines = @funder.funding_lines
    display @funding_lines
  end

  def show
    @funding_line = NewFundingLine.get(params[:id])
    raise NotFound unless @funding_line
    display @funding_line
  end

  def list
    # GATE-KEEPING
    @errors = []
    funder_id = params[:id]
    @funder = NewFunder.get funder_id

    # OPERATIONS PERFORMED
    begin
      @funding_lines = @funder.new_funding_lines(:order => [:created_at.asc])
    rescue => ex
      @errors << ex.message
    end

    # RENDER/RE-DIRECT
    display [@funding_line, @funder]
  end

  def new
    @funder = NewFunder.get(params[:new_funder_id])
    @funding_line = NewFundingLine.new
    display @funding_line
  end

  def create
    # INITIALIZING VARIABLES USED THROUGHOUT
    message = {}
    @errors = []
    # GATE-KEEPING
    funder_id = params[:new_funder_id]
    amount_str = params[:amount]
    sanction_date = params[:new_funding_line][:sanction_date]
    @funder = NewFunder.get(funder_id)

    # VALIDATIONS
    @errors << "Amount must not be blank" if amount_str.blank?
    @errors << "Sanction date must not be blank" if sanction_date.blank?
    # OPERATIONS-PERFORMED
    if @errors.blank?
      begin
        @money = MoneyManager.get_money_instance(amount_str)
        amount = @money.amount
        currency = @money.currency
        @funding_line = @funder.new_funding_lines.create({:amount => amount, :currency => currency, :new_funder_id => funder_id, :created_by => session.user.id, :sanction_date => sanction_date})
        if @funding_line.save!
          #used save! method to bypass an error which was disallowing it to save amounts in crores from front end but from backend it was working fine.
          #added a custom code for making entry in audit_trail table for tracking history.
          audit_params = {:auditable_id => @funding_line.id, :auditable_type => "NewFundingLine", :action => :create,
            :changes => [{:created_by=>[nil, session.user.id]}, {:created_at=>[nil, @funding_line.created_at]}, {:sanction_date=>[nil, sanction_date]}, {:new_funder_id=>[nil, funder_id]}, {:currency=>[nil, currency]}, {:amount=>[nil, amount]}],
            :created_at => DateTime.now, :user_role => session.user.staff_member.designation.role_class, :user_id => session.user.id, :type => :log}
          @audit_trail = AuditTrail.new(audit_params)
          @audit_trail.save
          message = {:notice => "Funding Line was successfully created"}
        else
          message = {:error => @funding_line.errors.first}
        end
      rescue => ex
        message = {:error => ex.message}
      end
      redirect url("new_funders/#{@funder.id}"), :message => message
    else
      @funding_line = @funder.new_funding_lines.new({:amount => amount, :currency => currency, :new_funder_id => funder_id, :created_by => session.user.id, :sanction_date => sanction_date})
      redirect url("new_funders/#{@funder.id}/new_funding_lines/new"), :message => {:error => @errors.flatten.join(', ')}
    end
  end

  def edit
    @funding_line = NewFundingLine.get(params[:id])
    @funder = @funding_line.new_funder
    raise NotFound unless @funding_line
    display @funding_line
  end

  def update
    @funding_line = NewFundingLine.get(params[:id])
    raise NotFound unless @funding_line
    @funder = NewFunder.get(params[:new_funder_id])
    amount_str = params[:new_funding_line][:amount]
    @money = MoneyManager.get_money_instance(amount_str)
    amount = @money.amount
    currency = @money.currency
    sanction_date = params[:new_funding_line][:sanction_date]
    if @funding_line.update_attributes({:amount => amount, :currency => currency, :new_funder_id => @funder.id, :created_by => session.user.id, :sanction_date => sanction_date})
      redirect url("new_funders/#{@funder.id}"), :message => {:notice => "Funding Line details updated successfully"}
    else
      redirect url("new_funders/#{@funder.id}/new_funding_lines/#{@funding_line.id}/edit"), :message => {:error => "Details of Funding Line cannot be updated because: #{@funding_line.errors.instance_variable_get("@errors").map{|k, v| v.join(", ")}.join(", ")}"}
    end
  end

end
