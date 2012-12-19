class Report
  include DataMapper::Resource

  attr_accessor :raw
  property :id, Serial
  property :start_date, Date
  property :end_date, Date
  property :report, Yaml, :length => 20000
  property :dirty, Boolean
  property :report_type, Discriminator
  property :created_at, DateTime
  property :generation_time, Integer

  validates_with_method :from_date, :method => :from_date_should_be_less_than_to_date

  def name
    "#{report_type}: #{start_date} - #{end_date}"
  end

  def get_parameters(params, user=nil)
    staff     = user.staff_member if user
    @account = Account.all(:order => [:name])

    [:loan_product_id, :late_by_more_than_days, :more_than, :late_by_less_than_days, :attendance_status, :include_past_data, :include_unapproved_loans].each{|key|
      if params and params[key] and params[key].to_i>0
        instance_variable_set("@#{key}", params[key].to_i)
      end
    }
    set_instance_variables(params)
  end

  def calc
    t0 = Time.now
    all(:report_type => self.report_type, :start_date => self.start_date, :end_date => self.end_date).destroy!
    self.report = Marshal.dump(self.generate)
    self.generation_time = Time.now - t0
    self.save
  end

  def get_pdf
    pdf = PDF::HTMLDoc.new
    pdf.set_option :bodycolor, :white
    pdf.set_option :toc, false
    pdf.set_option :portrait, true
    pdf.set_option :links, true
    pdf.set_option :webpage, true
    pdf.set_option :left, '2cm'
    pdf.set_option :right, '2cm'
    pdf.set_option :header, "Header here!"
    f = File.read("app/views/reports/_#{name.snake_case.gsub(" ","_")}.pdf.haml")
    report = Haml::Engine.new(f).render(Object.new, :report => self)
    pdf << report
    pdf.footer ".t."
    pdf
  end

  def get_xls
    f   = File.read("app/views/reports/_#{self.class.to_s.snake_case.gsub(' ', '_')}.html.haml").gsub("=partial :form\n", "")
    doc = Hpricot(Haml::Engine.new(f).render(Object.new, "@data" => self.generate))
    headers = doc.search("tr.header").map{|tr|
      tr.search("th").map{|td|
        [td.inner_text.strip => td.attributes["colspan"].blank? ? 1 : td.attributes["colspan"].to_i]
      }
    }.map{|x|
      x.reduce([]){|s,x| s+=x}
    }
  end

  def process_conditions(conditions)
    selects = []
    conditions = conditions.map{|query, value|
      key      = get_key(query)
      operator = get_operator(query, value)
      value    = get_value(value)
      operator = " is " if value == "NULL" and operator == "="
      next if not key
      "#{key}#{operator}#{value}"
    }
    query = ""
    query = " AND " + conditions.join(' AND ') if conditions.length>0
    [query, selects.join(', ')]
  end

  def get_key(query)
    if query.class==DataMapper::Query::Operator
      return query.target
    elsif query.class==String
      return query
    elsif query.class==Symbol and query==:fields
      return nil
    else
      return query
    end
  end

  def get_operator(query, value)
    if query.respond_to?(:operator)
      case query.operator
      when :lte
        "<="
      when :gte
        ">="
      when :gt
        ">"
      when :lt
        "<"
      when :eq
        "="
      when :not
        " is not "
      else
        "="
      end
    elsif value.class == Array
      " in "
    else
      "="
    end
  end

  def get_value(val)
    if val.class==Date
      "'#{val.strftime("%Y-%m-%d")}'"
    elsif val.class==Array
      "(#{val.join(",")})"
    elsif val.nil?
      "NULL"
    else
      val
    end
  end

  def date_should_not_be_in_future
    return [false, "Date cannot be in futute"] if self.respond_to?(:date) and self.date > Date.today
    return [false, "From date cannot be in futute"] if self.respond_to?(:from_date) and self.from_date > Date.today
    return [false, "To date cannot be in futute"] if self.respond_to?(:to_date) and self.to_date > Date.today
    return true
  end

  def branch_should_be_selected
    return [false, "Branch needs to be selected"] if self.respond_to?(:biz_location_branch) and not self.biz_location_branch
    return true
  end

  def funding_line_not_selected
    return [false, "Please select Funding Line"] if self.respond_to?(:funding_line_id) and not self.funding_line_id
    return true
  end

  def from_date_should_be_less_than_to_date
    if @from_date and @to_date and @from_date > @to_date
      return [false, "From date should be before to date"]
    end
    return true
  end

  private

  def set_instance_variables(params)
    params.each{|key, value|
      instance_variable_set("@#{key}", value.to_i) if not [:date, :from_date, :to_date].include?(key.to_sym) and value and value.to_i>0
    } if params
  end

end