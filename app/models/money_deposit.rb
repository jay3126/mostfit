class MoneyDeposit
  include DataMapper::Resource
  
  property :id, Serial
  property :created_on, Date, :default => Date.today
  property :created_at, Date, :default => Date.today
  property :created_by_user_id, Integer, :nullable => false
  property :created_by_staff_id, Integer, :nullable => false

  belongs_to :bank_account
  belongs_to :user, :child_key => [:created_by_user_id], :model => 'User'
  belongs_to :staff_member, :child_key => [:created_by_staff_id], :model => 'StaffMember'


end
