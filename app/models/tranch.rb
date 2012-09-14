class Tranch
  include DataMapper::Resource
  include Constants::Properties

  property :id,                   Serial
  property :name,                 *NAME
  property :date_of_commencement, *DATE_NOT_NULL
  property :created_at,           *CREATED_AT

  belongs_to :funding_line

  validates_present :funding_line, :name, :date_of_commencement
  validates_is_unique :name, :scope => [:funding_line]

  has n, :funds_sources
  has n, :lendings, :through => :funds_sources

  def created_on; self.date_of_commencement; end

end