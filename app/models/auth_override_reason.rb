class AuthOverrideReason
	include DataMapper::Resource

	property :id, Serial
	property :reason, String,:unique=>true,:nullable=>false
	property :active, Boolean
	property :deleted, Boolean,:default=>false
	property :created_at, DateTime
	property :deleted_at, DateTime
	property :created_by_id, Integer
	property :deleted_by_id, Integer
	before   :create,			:valid?

	def create
		created_at=Time.now
		if deleted==true      	  
      raise NoMethodError, "deleted cant be set to true while creating new record"
    else
      super
    end
  end

  def save
    if !deleted or (deleted and !deleted_by_id.nil?)
      super
    else
      raise NoMethodError, "Deleted_by cant be set to nil while deleting a record"
    end
  end

  def destroy
    self.deleted=true
    self.save
    #puts "Cannot be deleted"
    return true
  end

  def update
    puts "Cannot be edited"
    return false
  end

end
