class OverlapReportResponse
  include DataMapper::Resource
  include Constants::Masters
  include OverlapReportInterpreter
  
  property :id,                  Serial
  property :created_at,          DateTime
  property :created_by_user_id,  Integer
  property :total_outstanding,   Integer
  property :no_of_active_loans,  Integer
  property :loan_application_id, Integer
  property :not_matched,         Boolean, :nullable => false
  property :response_text,       Text # Marshal.dump of response hash

  # this checks the response against the accepted limits and marks the status appropriately
  def process_response
    unless self.response_text.blank?
      r = JSON::parse(response_text)
      check = nil
      no_of_active_accounts = r["HEADER"]["SUMMARY"]["NO_OF_ACTIVE_ACCOUNTS"].to_i
      no_of_mfis = r["HEADER"]["SUMMARY"]["NO_OF_OTHER_MFIS"].to_i
      self.no_of_active_loans = r["HEADER"]["SUMMARY"]["NO_OF_ACTIVE_ACCOUNTS"].to_i
      responses = [r["RESPONSES"]["RESPONSE"]].flatten rescue []
      sum = 0
      responses.each{|x| sum += x["LOAN_DETAILS"]["CURRENT_BAL"].to_i}
      self.total_outstanding = sum
      existing_loans_amount = 0
      responses.each{|x| existing_loans_amount += x["LOAN_DETAILS"]["DISBURSED_AMT"].to_f}
      active_loans_number = 0 
      responses.each{|x| existing_loans_amount += x["LOAN_DETAILS"]["DISBURSED_AMT"].to_f}
      self.not_matched = false
      # if (no_of_active_accounts >= 2) or ((loan.amount + existing_loans_amount) >= 50000)
      #   self.status = :rejected          
      # else
      #   self.status = :accepted
      # end
    else
      self.not_matched = true
    end
    self.save
  end

  # to_be replaced
  def status
    rate_report
  end

  # Returns the loan amount applied for on the loan application that this overlap report response was received for
  # Returns nil if it cannot find this amount
  def applied_for_amount
    return nil unless self.loan_application_id
    loan_application = Loan.get(self.loan_application_id)
    (loan_application and loan_application.amount) ? loan_application.amount : nil
  end

end
