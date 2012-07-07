module Identified

  def name_and_id
    describe = ""
    if respond_to?(:name) && name
      describe += "#{name}"
      text_added = true
    end
    describe += (text_added ? " (#{id})" : "(#{id})") if respond_to?(:id) && id
  end

  def to_s
    "#{self.class.name} #{name_and_id}"
  end

end