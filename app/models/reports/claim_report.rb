class ClaimReport < Report
  attr_accessor :from_date, :to_date

  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end

  def self.name
    "Claim Report"
  end

  def name
    "Claim Report from #{@from_date} to #{@to_date}"
  end

  def generate
    branches, centers, claims = {}, {}, {}

    #These 4 params are to implement 4 conditions:-
    #IF Date of death OR Date of Submission of Claim OR Date of receipt of claim from insurance company OR Date of payment to client
    #then the data for claim is to be displyed.

    params = {:claim_submission_date.gte => @from_date, :claim_submission_date.lte => @to_date, :order => [:claim_submission_date]}
    params1 = {:date_of_death.gte => @from_date, :date_of_death.lte => @to_date, :order => [:date_of_death]}
    params2 = {:receipt_of_claim_on.gte => @from_date, :receipt_of_claim_on.lte => @to_date, :order => [:receipt_of_claim_on]}
    params3 = {:payment_to_client_on.gte => @from_date, :payment_to_client_on.lte => @to_date, :order => [:payment_to_client_on]}
 
    #claims = (Claim.all(params) + Claim.all(:claim_submission_date => nil, :order => [:claim_submission_date]))

    #if any 1 of the below condition is fulfilled then display the data.
    claims = Claim.all(params) || Claim.all(params1) || Claim.all(params2) || Claim.all(params3)
    claims.group_by{ |claim| claim.client.center.branch} 
  end
end
