class AccountGroup
  include DataMapper::Resource
  include Constants::Accounting
  
  property :id,           Serial
  property :name,         String, :nullable => false
  property :account_type, Enum.send('[]', *ACCOUNT_TYPES), :nullable => false
  
  has n, :ledgers

  def self.load_accounts_groups(groups_hash)
  	account_types = groups_hash.keys
  	account_types.each { |type|
      names = groups_hash[type]
      names.each { |group_name|
  	    first_or_create(:name => group_name, :account_type => type.to_sym)	
      }
  	}
  end

end
