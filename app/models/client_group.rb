class ClientGroup
  include DataMapper::Resource
  include Constants::Properties

  #before :valid?, :add_created_by_staff_member

  property :id,                Serial
  property :name,              String, :nullable => false
  property :number_of_members, Integer, :nullable => true, :min => 1, :max => 20, :default => 5
  property :code,              String, :length => 100, :nullable => false, :index => true
  property :created_by_staff_member_id,  Integer, :nullable => false, :index => true
  property :created_at, *CREATED_AT
  property :creation_date, Date, :nullable => false, :default => Date.today

  validates_length      :code, :min => 1, :max => 100

  has n, :clients
  belongs_to :biz_location, :nullable => true
  belongs_to :created_by_staff,  :child_key => [:created_by_staff_member_id], :model => 'StaffMember'

  validates_is_unique :name, :scope => :biz_location_id
  validates_is_unique :code, :scope => :biz_location_id

  # def self.from_csv(row, headers)
  #   center = Center.first(:code => row[headers[:center_code]])
  #   obj    = new(:name => row[headers[:name]], :center_id => center.id, :code => row[headers[:code]], :upload_id => row[headers[:upload_id]])
  #   [obj.save, obj]
  # end

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
