class NewDailyReport < Report
  attr_accessor :date, :biz_location_branch

  def initialize(params, dates, user)
    @date = dates[:date] || Date.today
    @name = "Daily Report for #{@date}"
    location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, @user)
    branches = location_facade.all_nominal_branches
    @biz_location_branch = (params and params[:biz_location_branch] and (not (params[:biz_location_branch].empty?))) ? params[:biz_location_branch] : branches
    get_parameters(params, user)
  end

  def name
    "New Daily Report for #{@date}"
  end

  def self.name
    "New Daily Report"
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate
    data , loan_applied_amount , loan_approved_amount , loan_disbursed_amount = {}, {}, {}, {}
    loan_collections = []

    loan_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOAN_FACADE, @user)
    #handling condition when only one choice is selected. It gives the id of the bizlocation so checking it with the class of biz_location.
    if (@biz_location_branch and @biz_location_branch.class == Fixnum) 
      biz_location = BizLocation.get(@biz_location_branch)
      loan = loan_facade.get_loans_at_location(biz_location.id, @date)
      loan_ids = loan.map{|l| l.id}

      #handling cases if loan_ids are empty.
      if loan_ids.empty?
        loan_applied_amount[biz_location.name] = 0
        loan_approved_amount[biz_location.name] = 0
        loan_disbursed_amount[biz_location.name] = 0

      else
        applied_amount = Lending.all(:id => loan_ids, :applied_on_date => @date).aggregate(:applied_amount.sum)
        if applied_amount.nil?
          loan_applied_amount[biz_location.name] = 0
        else
          loan_applied_amount[biz_location.name] = applied_amount
        end

        approved_amount = Lending.all(:id => loan_ids, :approved_on_date => @date).aggregate(:approved_amount.sum)
        if approved_amount.nil?
          loan_approved_amount[biz_location.name] = 0
        else
          loan_approved_amount[biz_location.name] = approved_amount
        end

        disbursed_amount = Lending.all(:id => loan_ids, :disbursal_date => @date).aggregate(:disbursed_amount.sum)
        if disbursed_amount.nil?
          loan_disbursed_amount[biz_location.name] = 0
        else
          loan_disbursed_amount[biz_location.name] = disbursed_amount
        end
      end

    else
      #when no choice is selected, we get a collection of all the biz_locations.
      @biz_location_branch.each do |biz_location|
        loans = loan_facade.get_loans_at_location(biz_location.id, @date)
        loan_ids = loans.map{|l| l.id}

        if loan_ids.empty?
          loan_applied_amount[biz_location.name] = 0
          loan_approved_amount[biz_location.name] = 0
          loan_disbursed_amount[biz_location.name] = 0

        else
          applied_amount = Lending.all(:id => loan_ids, :applied_on_date => @date).aggregate(:applied_amount.sum)
          if applied_amount.nil?
            loan_applied_amount[biz_location.name] = 0
          else
            loan_applied_amount[biz_location.name] = applied_amount
          end

          approved_amount = Lending.all(:id => loan_ids, :approved_on_date => @date).aggregate(:approved_amount.sum)
          if approved_amount.nil?
            loan_approved_amount[biz_location.name] = 0
          else
            loan_approved_amount[biz_location.name] = approved_amount
          end

          disbursed_amount = Lending.all(:id => loan_ids, :disbursal_date => @date).aggregate(:disbursed_amount.sum)
          if disbursed_amount.nil?
            loan_disbursed_amount[biz_location.name] = 0
          else
            loan_disbursed_amount[biz_location.name] = disbursed_amount
          end
        end

      end
    end

    #loop for sending the data to view side.
    if (@biz_location_branch and @biz_location_branch.class == Fixnum)
      biz_location = BizLocation.get(@biz_location_branch)
      loan_amounts_map = {:amount_applied => loan_applied_amount.values[0], :amount_approved => loan_approved_amount.values[0], :amount_disbursed => loan_disbursed_amount.values[0]}
      loan_money_amounts_map = Money.money_amounts_hash_to_money(loan_amounts_map, default_currency)
      data[biz_location.name] = {:loans => loan_money_amounts_map }

    else
      @biz_location_branch.each do |biz_location|
        loan_amounts_map = {:amount_applied => loan_applied_amount[biz_location.name], :amount_approved => loan_approved_amount[biz_location.name], :amount_disbursed => loan_disbursed_amount[biz_location.name]}
        loan_money_amounts_map = Money.money_amounts_hash_to_money(loan_amounts_map, default_currency)
        data[biz_location.name] = {:loans => loan_money_amounts_map }
      end
    end

    return data
    
=begin
    The report will be filtered with branch as of now.
    daily report will have following columns :-
    2. Repayment amounts (Principal, Interest, Total, Fees)
    3. Balance Outstandings (Principal, Interest, Total)
    4. Balance Overdue (Principal, Interest, Total)
    5. Advance Payments (Collected, Adjusted, Balance)
=end
  end
end
