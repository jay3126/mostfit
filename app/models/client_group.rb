class ClientGroup
  include DataMapper::Resource

  include Constants::Properties

  property :id,                Serial
  property :name,              String, :nullable => false
  property :number_of_members, Integer, :nullable => true, :min => 1, :max => 20, :default => 5
  property :code,              String,  :length => 50, :nullable => false, :index => true
  property :created_by_staff_member_id,  Integer, :nullable => false, :index => true
  property :created_at, *CREATED_AT
  property :creation_date, Date, :nullable => false, :default => Date.today

 if Mfi.first.system_state != :migration
    validates_length :code, :min => 2, :max => 2
 end

  has n, :clients
  belongs_to :biz_location, :nullable => true
  belongs_to :created_by_staff,  :child_key => [:created_by_staff_member_id], :model => 'StaffMember'

  validates_is_unique :name, :scope => :biz_location_id
  validates_is_unique :code, :scope => :biz_location_id
  belongs_to :upload, :nullable => true
   

  def self.from_csv(row, headers)
    biz_location = BizLocation.first(:name => row[headers[:center]])
    obj    = new(:name => row[headers[:name]], :biz_location_id => biz_location.id, :code => row[headers[:code]],
                 :number_of_members => row[headers[:number_of_members]], :created_by_staff_member_id => User.first.staff_member.id,
                 :creation_date => row[headers[:creation_date]], :upload_id => row[headers[:upload_id]])
    [obj.save, obj]
  end

  def self.search(q, per_page=10)
    if /^\d+$/.match(q)
      all(:conditions => ["id = ? or code=?", q, q], :limit => per_page)
    else
      all(:conditions => ["code=? or name like ?", q, q+'%'], :limit => per_page)
    end
  end

  def add_created_by_staff_member
    if self.center and self.new?
      self.created_by_staff_member_id = self.center.manager_staff_id
    end
  end
end
