class MoneyDepositCategory
  include DataMapper::Resource
  
  property :id,              Serial
  property :category_name,   String, :unique => true, :nullable => false
  property :created_at,      DateTime,         :nullable => false, :default => DateTime.now
  property :deleted_at,      ParanoidDateTime
  property :updated_at,      DateTime

  belongs_to :created_by_staff,     :child_key => [:created_by_staff_member_id], :model => 'StaffMember'
  belongs_to :created_by,  :child_key => [:created_by_user_id], :model => 'User'

  def created_by_staff
    staff_name = StaffMember.get(self.created_by_staff_member_id)
    staff_name.nil? ? nil : staff_name.name
  end

  def created_by_user
    user_name = User.get(self.created_by_user_id)
    user_name.nil? ? nil : user_name.name
  end

end
