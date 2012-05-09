module PostingValidator
  include Constants::Accounting

  def has_both_debits_and_credits?(postings)
  	effects = (postings.collect {|p| p.effect}).uniq
  	(effects.length == 2 and effects.include?(DEBIT_EFFECT) and effects.include?(CREDIT_EFFECT)) ? true :
  	  [false, "postings don't represent both debits and credits"]
  end

  def each_is_valid_quantity?(postings)
  	postings.each { |p|
  	  return [false, "posting amount #{p.amount} is invalid"] if ((p.amount <= 0) or (p.amount > 100))
  	}
  	true
  end  

  def each_side_accounts_fully?(postings)
  	postings_by_effect = postings.group_by {|p| p.effect}
  	postings_by_effect.each { |effect, ps|
  	  amounts = ps.collect {|p| p.amount}
  	  total = amounts.inject {|sum, each_amount| sum + each_amount}
  	  return [false, "postings for #{effect} don't account for the full amount"] unless (total == 100)
  	}
  	true
  end

  def all_post_to_unique_accounts?(postings)
  	all_ledgers = postings.collect {|p| p.ledger}
  	all_ledgers.uniq! ? [false, "postings do not post to unique accounts: #{all_ledgers}"] : true
  end

end