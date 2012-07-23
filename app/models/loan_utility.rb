module LoanUtility

  # Returns the most recent transaction on the loan, and nil if there were none
  # In the event that there was a receipt and a payment on the same date, the receipt is preferably returned
  def most_recent_payment_transaction
    most_recent_loan_payment = self.most_recent_payment
    payment_date = most_recent_loan_payment ? most_recent_loan_payment.effective_on : nil

    most_recent_loan_receipt = self.most_recent_receipt
    receipt_date = most_recent_loan_receipt ? most_recent_loan_receipt.effective_on : nil

    if (payment_date and receipt_date)
      most_recent_transaction = (receipt_date >= payment_date) ? most_recent_loan_receipt : most_recent_loan_payment
      return most_recent_transaction
    end
    most_recent_loan_receipt || most_recent_loan_payment
  end

  def most_recent_payment
    self.loan_payments.first(:order => [:effective_on.desc])
  end

  def most_recent_receipt
    self.loan_receipts.first(:order => [:effective_on.desc])
  end

  # Returns the date of the most recent transaction on the loan, and nil if there were none
  def most_recent_payment_transaction_on_date
    most_recent_payment_transaction ? most_recent_payment_transaction.effective_on : nil
  end

  def has_loan_claim?
    self.loan_claims and (not (self.loan_claims.empty?))
  end

  def has_loan_claim_since
    return nil unless self.has_loan_claim?
    earliest_claim = self.loan_claims.sort.first
    earliest_claim.created_on
  end
    
end