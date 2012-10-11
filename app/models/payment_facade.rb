class PaymentFacade < StandardFacade

  # QUERIES

  def get_payments_recorded(on_loan, on_date = Date.today)
    #TBD
  end

  def get_payments_effective(on_loan, on_date = Date.today)
    #TBD
  end

  # UPDATES

  def is_loan_payment_permitted?(payment_transaction)    
    loan_facade.is_loan_payment_permitted?(payment_transaction)
  end

  def record_ad_hoc_fee_receipt(fee_money_amount, fee_product, effective_on, fee_recorded_on_type, performed_by_id)
    FeeReceipt.record_ad_hoc_fee(fee_money_amount, fee_product, effective_on, fee_recorded_on_type, performed_by_id, for_user.id)
  end

  def record_fee_receipts(fee_receipt_info_list)
    fee_receipt_manager.record_fee_receipts(*fee_receipt_info_list)
  end

  def record_payment(money_amount, receipt_type, payment_towards, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, product_action, make_specific_allocation = false, specific_principal_money_amount = nil, specific_interest_money_amount = nil)
    payment_transaction = PaymentTransaction.record_payment(money_amount, receipt_type, payment_towards, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, for_user.id)
    payment_allocation = loan_facade.allocate_payment(payment_transaction, on_product_id, product_action, make_specific_allocation, specific_principal_money_amount, specific_interest_money_amount, '')
    accounting_facade.account_for_payment_transaction(payment_transaction, payment_allocation)
  end

  def record_fee_payment(fee_instance_id, money_amount, receipt_type, payment_towards, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, product_action, make_specific_allocation = false, specific_principal_money_amount = nil, specific_interest_money_amount = nil)
    payment_transaction = PaymentTransaction.record_payment(money_amount, receipt_type, payment_towards, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, for_user.id)
    payment_allocation = loan_facade.allocate_payment(payment_transaction, on_product_id, product_action, make_specific_allocation, specific_principal_money_amount, specific_interest_money_amount, fee_instance_id)
    accounting_facade.account_for_payment_transaction(payment_transaction, payment_allocation)
  end

  def record_adjust_advance_payment(money_amount, receipt_type, payment_towards, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, product_action, adjust_complete_advance = false)
    payment_transaction = PaymentTransaction.record_payment(money_amount, receipt_type, payment_towards, on_product_type, on_product_id, by_counterparty_type, by_counterparty_id, performed_at, accounted_at, performed_by, effective_on, for_user.id)
    payment_allocation = loan_facade.allocate_payment(payment_transaction, on_product_id, product_action, false, nil, nil, '', adjust_complete_advance)
    accounting_facade.account_for_payment_transaction(payment_transaction, payment_allocation)
  end

  private

  def loan_facade
    @loan_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::LOAN_FACADE, self)
  end

  def accounting_facade
    @accounting_facade ||= FacadeFactory.instance.get_other_facade(FacadeFactory::ACCOUNTING_FACADE, self)
  end

  def fee_receipt_manager
    @fee_receipt_manager ||= FeeReceiptManager.new(@for_user.id)
  end

end
