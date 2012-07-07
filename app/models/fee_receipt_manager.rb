class FeeReceiptManager

  attr_reader :created_at, :recorded_by_id
  
  def initialize(recorded_by_id)
    @created_at = DateTime.now
    @recorded_by_id = recorded_by_id
  end

  def record_fee_receipts(*fee_receipt_info)
    fee_receipt_info.each { |fr_info|
      fee_instance     = fr_info.fee_instance
      fee_money_amount = fr_info.fee_money_amount
      effective_on     = fr_info.effective_on
      performed_by_id  = fr_info.performed_by_id
      FeeReceiptInfo.record_fee_receipt(fee_instance, fee_money_amount, effective_on, performed_by_id, @recorded_by_id)
    }
  end

end
