module LoanUtility

  def most_recent_payment_transaction_on_date
    most_recent_loan_payment = self.loan_payments.first(:order => [:effective_on.desc])
    payment_date = most_recent_loan_payment ? most_recent_loan_payment.effective_on : nil

    most_recent_loan_receipt = self.loan_receipts.first(:order => [:effective_on.desc])
    receipt_date = most_recent_loan_receipt ? most_recent_loan_receipt.effective_on : nil

    payment_date ? (receipt_date ? [payment_date, receipt_date].max : payment_date) : nil
  end
    
end
