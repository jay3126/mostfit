module LoanValidations

  DATE_VALIDATIONS = [
    :applied_date_scheduled_disbursal_date_and_scheduled_first_repayment_dates_are_all_supplied?,
    :scheduled_disbursal_and_first_repayment_date_are_both_supplied?,
    :dates_are_ordered?,
    :scheduled_disbursal_and_scheduled_first_repayment_dates_are_ordered?
  ]
  
  def applied_date_scheduled_disbursal_date_and_scheduled_first_repayment_dates_are_all_supplied?
    return true if (applied_on_date and scheduled_disbursal_date and scheduled_first_repayment_date)
    [false, "When a loan is applied, the applied date, scheduled disbursal date, and scheduled first repayment dates must be supplied"]
  end

  def scheduled_disbursal_and_first_repayment_date_are_both_supplied?
    if (((scheduled_disbursal_date.nil? and (not (scheduled_first_repayment_date.nil?)))) or
        ((scheduled_first_repayment_date.nil? and (not (scheduled_disbursal_date.nil?)))))
      return [false, "When specified, both scheduled disbursal date and scheduled first repayment date must be supplied"]
    end
    true
  end

  def dates_are_ordered?
    if (approved_on_date)
      return [false, "Approved on date: #{approved_on_date} cannot precede applied on date: #{applied_on_date}"] if (applied_on_date > approved_on_date)
      if (disbursal_date)
        return [false, "Actual disbursal date: #{disbursal_date} cannot precede applied on date: #{applied_on_date}"] if (applied_on_date > disbursal_date)
        return [false, "Actual disbursal date: #{disbursal_date} cannot precede approved on date: #{approved_on_date}"] if (approved_on_date > disbursal_date)
      end
    end
    true
  end

  def scheduled_disbursal_and_scheduled_first_repayment_dates_are_ordered?
    if (scheduled_disbursal_date and scheduled_first_repayment_date)
      return [false, "Scheduled disbursal date must precede scheduled first repayment date"] if (scheduled_disbursal_date >= scheduled_first_repayment_date)
    end
    true
  end
    
end