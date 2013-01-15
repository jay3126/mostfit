class Comment
  include DataMapper::Resource
  include Constants::Properties
  
  property :id, Serial
  
  property :text,              Text, :min => 5
  property :commentable_class, String
  property :commentable_id,    Integer
  property :created_on,        Date
  property :created_at,        *CREATED_AT
  property :updated_at,        *UPDATED_AT
  property :deleted_at,        *DELETED_AT
  
  belongs_to :user
  belongs_to :reason

  def self.comments_on_lending(lending_id)
    all(:commentable_class => 'Lending', :commentable_id => lending_id )
  end

  def self.lending_to_s(lending_id)
    comments = comments_on_lending(lending_id).map{|c| "#{c.reason.name.humanize}:- #{c.text}"} rescue []
    comments.blank? ? [] : comments
  end

  def self.save_comment(text, reason_id, commentable_type, commentable_id, user_id, created_on = Date.today)
    values = {}
    values[:text] = text
    values[:reason_id] = reason_id
    values[:commentable_class] = commentable_type
    values[:commentable_id] = commentable_id
    values[:user_id] = user_id
    values[:created_on] = created_on
    create(values)
  end

  def self.for(object)
    Comment.all(:parent_model => object.class.to_s, :parent_id => object.id)
  end

end
