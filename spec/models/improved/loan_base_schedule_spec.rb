require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )

describe LoanBaseSchedule do

  before(:all) do
    @loan = Factory(:lending)

    @principal_and_interest_amounts = {}

    @principal_amounts            = [170.18, 171.03, 171.88, 172.74, 173.60, 174.46, 175.33, 176.21, 177.08, 177.97, 178.85, 179.74, 180.64, 181.54, 182.44, 183.35, 184.27, 185.18, 186.11, 187.03, 187.97, 188.90, 189.84, 190.79, 191.74, 192.69, 193.65, 194.62, 195.59, 196.56, 197.54, 198.53, 199.52, 200.51, 201.51, 202.51, 203.52, 204.53, 205.55, 206.58, 207.61, 208.64, 209.68, 210.73, 211.77, 212.83, 213.89, 214.96, 216.03, 217.10, 218.18, 146.30]
    @principal_money_amounts      = MoneyManager.get_money_instance(*@principal_amounts)
    zero_money_amount             = Money.zero_money_amount(Constants::Money::DEFAULT_CURRENCY)
    @total_principal_money_amount = @principal_money_amounts.inject(zero_money_amount) { |sum, money_amt| sum + money_amt }

    @interest_amounts            = [49.82, 48.97, 48.12, 47.26, 46.40, 45.54, 44.67, 43.79, 42.92, 42.03, 41.15, 40.26, 39.36, 38.46, 37.56, 36.65, 35.73, 34.82, 33.89, 32.97, 32.03, 31.10, 30.16, 29.21, 28.26, 27.31, 26.35, 25.38, 24.41, 23.44, 22.46, 21.47, 20.48, 19.49, 18.49, 17.49, 16.48, 15.47, 14.45, 13.42, 12.39, 11.36, 10.32, 9.27, 8.23, 7.17, 6.11, 5.04, 3.97, 2.90, 1.82, 0.73]
    @interest_money_amounts      = MoneyManager.get_money_instance(*@interest_amounts)
    zero_money_amount            = Money.zero_money_amount(Constants::Money::DEFAULT_CURRENCY)
    @total_interest_money_amount = @interest_money_amounts.inject(zero_money_amount) { |sum, money_amt| sum + money_amt }

    1.upto(@principal_amounts.length) { |num|
      principal_and_interest                                           = { }
      principal_and_interest[Constants::Transaction::PRINCIPAL_AMOUNT] = @principal_money_amounts[num - 1]
      principal_and_interest[Constants::Transaction::INTEREST_AMOUNT]  = @interest_money_amounts[num - 1]
      @principal_and_interest_amounts[num]                             = principal_and_interest
    }

    @principal_and_interest_amounts[0] = {
        Constants::Transaction::PRINCIPAL_AMOUNT => @total_principal_money_amount,
        Constants::Transaction::INTEREST_AMOUNT  => @total_interest_money_amount
    }

  end

  it "should create a number of schedule line items as expected" do
    disbursal_date = Date.parse('2012-04-01')
    first_repayment_date = disbursal_date + 7
    repayment_frequency = MarkerInterfaces::Recurrence::WEEKLY
    tenure = 52
    num_of_installments = 52
    lending = @loan

    base_schedule = LoanBaseSchedule.create_base_schedule(@total_principal_money_amount, @total_interest_money_amount, disbursal_date, first_repayment_date, repayment_frequency, tenure, num_of_installments, lending, @principal_and_interest_amounts)
    base_schedule.saved?.should be_true
  end

end