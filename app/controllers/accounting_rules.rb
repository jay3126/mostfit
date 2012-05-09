class AccountingRules < Application
  # provides :xml, :yaml, :js

  def index
    @accounting_rules = AccountingRule.all
    display @accounting_rules
  end

  def show(id)
    @accounting_rule = AccountingRule.get(id)
    raise NotFound unless @accounting_rule
    display @accounting_rule
  end

  def new
    only_provides :html
    @accounting_rule = AccountingRule.new
    display @accounting_rule
  end

  def edit(id)
    only_provides :html
    @accounting_rule = AccountingRule.get(id)
    raise NotFound unless @accounting_rule
    display @accounting_rule
  end

  def create(accounting_rule)
    @accounting_rule = AccountingRule.new(accounting_rule)
    if @accounting_rule.save
      redirect resource(@accounting_rule), :message => {:notice => "AccountingRule was successfully created"}
    else
      message[:error] = "AccountingRule failed to be created"
      render :new
    end
  end

  def update(id, accounting_rule)
    @accounting_rule = AccountingRule.get(id)
    raise NotFound unless @accounting_rule
    if @accounting_rule.update(accounting_rule)
       redirect resource(@accounting_rule)
    else
      display @accounting_rule, :edit
    end
  end

  def destroy(id)
    @accounting_rule = AccountingRule.get(id)
    raise NotFound unless @accounting_rule
    if @accounting_rule.destroy
      redirect resource(:accounting_rules)
    else
      raise InternalServerError
    end
  end

end # AccountingRules
