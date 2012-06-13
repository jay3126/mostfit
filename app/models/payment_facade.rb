class PaymentFacade < StandardFacade

  # QUERIES

  def get_payments_recorded(on_loan, on_date = Date.today)
    #TBD
  end

  def get_payments_effective(on_loan, on_date = Date.today)
    #TBD
  end

  def get_payments_performed_on_date(at_location, effective_on = Date.today, by_staff = nil)
    PaymentTransaction.get_payments_performed_on_date(at_location, effective_on, by_staff)
  end

  def get_payments_performed_till_date(at_location, effective_on = Date.today, by_staff = nil)
    PaymentTransaction.get_payments_performed_till_date(at_location, effective_on, by_staff)
  end

  # UPDATES

  def record_payment(money_amount, receipt_type, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, product_action)
    payment_transaction = PaymentTransaction.record_payment(money_amount, receipt_type, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, for_user)

    payment_allocation = loan_facade.allocate_payment(payment_transaction, on_product_id, product_action)

    accounting_facade.account_for_payment_transaction(payment_transaction, payment_allocation)
  end

  private

  def loan_facade
    @loan_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::LOAN_FACADE, self)
  end

  def accounting_facade
    @accounting_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::ACCOUNTING_FACADE, self)
  end

end