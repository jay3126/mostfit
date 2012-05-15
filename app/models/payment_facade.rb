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

=begin
    product_type, product_id = Resolver.resolve_product(on_product)
    product_facade = FacadeFactory.get_other_facade(product_type, self)
    product_facade.account_for_payment(payment_transaction, product_id, product_action)
=end
    #book-keeping
    #book payment transaction on product account
  end

end