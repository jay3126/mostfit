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

=begin
 1 class Photo
 2   include DataMapper::Resource
 3
 4   property :id, Serial
 5
 6   has n, :taggings
 7   has n, :tags, :through => :taggings
 8 end
 9
10 class Tag
11   include DataMapper::Resource
12
13   property :id, Serial
14
15   has n, :taggings
16   has n, :photos, :through => :taggings
17 end
18
19 class Tagging
20   include DataMapper::Resource
21
22   belongs_to :tag,   :key => true
23   belongs_to :photo, :key => true
24 end
=end

end
