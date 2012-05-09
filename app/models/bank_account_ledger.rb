class BankAccountLedger < Ledger

  validates_with_method :is_asset_type?

  def is_asset_type?
  	account_type == ASSETS ? true : [false, "bank account ledgers must be set to account type #{ASSETS}"]
  end

end