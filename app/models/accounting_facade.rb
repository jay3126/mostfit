class AccountingFacade < StandardFacade

  def get_primary_chart_of_accounts
    book_keeper.get_primary_chart_of_accounts
  end

  def get_ledger(by_ledger_id)
    book_keeper.get_ledger(by_ledger_id)
  end

  def get_ledger_opening_balance_and_date(by_ledger_id)
    book_keeper.get_ledger_opening_balance_and_date(by_ledger_id)
  end

  def get_current_ledger_balance(by_ledger_id)
    book_keeper.get_ledger_current_balance(by_ledger_id)
  end

  def get_historical_ledger_balance(by_ledger_id, on_date)
    book_keeper.get_historical_ledger_balance(by_ledger_id, on_date)
  end

  def get_vouchers(involving_ledger_id, on_or_before_date)
    #TODO
  end

  private

  def book_keeper
    @book_keeper ||= MyBookKeeper.new
  end

end
