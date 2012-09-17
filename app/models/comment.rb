class Comment
  include DataMapper::Resource
  
  property :id, Serial
  
  property :text,              Text, :min => 5
  property :commentable_class, String
  property :commentable_id,    Integer
  property :created_at,        DateTime
  
  belongs_to :user
  belongs_to :reason

  def self.comments_on_lending(lending_id)
    all(:commentable_class => 'Lending', :commentable_id => lending_id )
  end

  def self.lending_to_s(lending_id)
    comments = comments_on_lending(lending_id)
    comments.blank? ? '' : comments.map{|c| "#{c.reason.name.humanize}:- #{c.text}"}
  end

  def self.save_comment(text, reason_id, commentable_type, commentable_id, user_id)
    values = {}
    values[:text] = text
    values[:region_id] = reason_id
    values[:commentable_class] = commentable_type
    values[:commentable_id] = commentable_id
    values[:user_id] = user_id
    create(values)
  end

  def self.for(object)
    Comment.all(:parent_model => object.class.to_s, :parent_id => object.id)
  end

end
