class Tranch
  include DataMapper::Resource

  property :id, Serial
  property :name, Text,:unique=>true,:nullable=>false
  property :date_of_commencement, Date,:nullable=>false

  belongs_to :funding_line

  validates_present :funding_line, :name, :date_of_commencement
  validates_is_unique :name, :scope => [:funding_line]


  def destroy
    puts "Cannot be deleted"
    return false
  end


end
