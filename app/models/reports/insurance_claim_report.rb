class InsuranceClaimReport < Report
  attr_accessor :claim_accounted_at, :claim_filed_on

  def initialize(params, date, user)
    @date = date.blank? ? Date.today : date
    @name   = "Report on #{@date}"
    @claim_accounted_at = params[:claim_accounted_at] rescue ""
    @claim_filed_on = params[:claim_filed_on] rescue ""
    get_parameters(params, user)
  end

  def name
    "Insurance Claim Report on #{@date}"
  end

  def self.name
    "Insurance Claim Report"
  end

  def generate
    condition_hash = {}
    condition_hash.merge!(:accounted_at => @claim_accounted_at) unless @claim_accounted_at.blank?
    condition_hash.merge!(:filed_on => @claim_filed_on) unless @claim_filed_on.blank?
    @data = InsuranceClaim.all(condition_hash)
  end
  
end