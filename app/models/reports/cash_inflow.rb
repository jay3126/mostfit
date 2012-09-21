class CashInflow < Report

  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name = "Cash Inflow from #{@from_date} to #{@to_date}"
    @user = user
    get_parameters(params, user)
  end

  def name
    "Cash Inflow from #{@from_date} to #{@to_date}"
  end

  def self.name
    "Cash Inflow Report"
  end

  def get_reporting_facade(user)
    @reporting_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::REPORTING_FACADE, user)
  end

  def get_location_facade(user)
    @location_facade ||= FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user)
  end

  def default_currency
    @default_currency = MoneyManager.get_default_currency
  end

  def generate

    reporting_facade = get_reporting_facade(@user)
    location_facade  = get_location_facade(@user)
    data = {}

    (@from_date..@to_date).each do |date|
      payment_transactions = PaymentTransaction.all(:effective_on => date, :receipt_type => :receipt)
      payment_amounts = payment_transactions.aggregate(:amount.sum)
      payment_amount = MoneyManager.get_money_instance(Money.new(payment_amounts.to_i, :INR).to_s)
      collection_date = date
      collection = (payment_transactions and (not payment_transactions.empty?)) ? PaymentTransaction.all(:effective_on => date, :receipt_type => :receipt, :payment_towards => [:payment_towards_loan_repayment, :payment_towards_loan_advance_adjustment, :payment_towards_loan_preclosure, :payment_towards_loan_recovery, :payment_towards_fee_receipt]).aggregate(:amount.sum) : 0
      actual_collection = MoneyManager.get_money_instance(Money.new(collection.to_i, :INR).to_s)
      total_collections = (payment_transactions and (not payment_transactions.empty?)) ? payment_transactions.aggregate(:amount.sum) : 0
      total_collection = MoneyManager.get_money_instance(Money.new(total_collections.to_i, :INR).to_s)
      max_amount = (payment_transactions and (not payment_transactions.empty?)) ? payment_transactions.aggregate(:amount.max) : 0
      maximum_amount = MoneyManager.get_money_instance(Money.new(max_amount.to_i, :INR).to_s)
      min_amount = (payment_transactions and (not payment_transactions.empty?)) ? payment_transactions.aggregate(:amount.min) : 0
      minimum_amount = MoneyManager.get_money_instance(Money.new(min_amount.to_i, :INR).to_s)
      if ((total_collections > 0) and (not payment_transactions.empty?))
        avg_amount = total_collections/payment_transactions.count
        average_amount = MoneyManager.get_money_instance(Money.new(avg_amount.to_i, :INR).to_s)
      else
        avg_amount = 0
        average_amount = MoneyManager.get_money_instance(Money.new(avg_amount.to_i, :INR).to_s)
      end

      data[date] = {:date => date, :payment_amount => payment_amount, :collection_date => collection_date, :actual_collection => actual_collection, :total_collection => total_collection, :maximum_amount => maximum_amount, :minimum_amount => minimum_amount, :average_amount => average_amount}
    end
    data
  end
end
