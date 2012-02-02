module Merb
  module CentersHelper
    def display_field_form(model, field, obj)
      val = obj.send(field)
      if relationship = model.relationships[field]
        name = "#{model.to_s.downcase}[#{obj.id}][#{field}]"
        @data ||= model.relationships[field].parent_model.all.map{|x| [x.id, x.respond_to?(:name) ? x.name : x.to_s]}
        return(select(:name => name, :collection => @data, 
                      :selected => (val ? val.id.to_s : ""), :include_blank => true))
      else
        # either we are setting a property directly or we are calling a method (see Client#loyalty_bonus_date for details why we would do this)
        method_types = {:loyalty_bonus_date => Date}
        property = model.properties.find{|x| x.name == field}
        type     = property ? property.type : method_types[field]
        name = "#{model.to_s.downcase}[#{obj.id}][#{field}]"
        if type == Integer
          return(text_field(:name => name, :value => obj.send(field), :size => 4))
        elsif type == String
          return(text_field(:name => name, :value => obj.send(field), :size => 10))
        elsif type == Date
          return(date_select(name, obj.send(field), :id => obj.id))
        elsif type==Class
          return(select(:name => name, :collection => property.type.flag_map.to_a.sort_by{|x| x[0]}.map{|x| [x[1], x[1]]}, :selected => (val ? val.to_s : "")))
        end
      end
    end
  end
end
