class NewFunder
  include DataMapper::Resource
  include Constants::Properties

  property :id,           Serial
  property :name,         String, :length => 50, :nullable => false, :unique => true
  property :created_by,   Integer
  property :created_at,   *CREATED_AT

  has n, :new_funding_lines

  def self.catalog
    result = {}
    funder_names = {}
    NewFunder.all(:fields => [:id, :name]).each { |f| funder_names[f.id] = f.name }
    NewFundingLine.all.each do |funding_line|
      funder = funder_names[funding_line.new_funder_id]
      result[funder] ||= {}
      result[funder][funding_line.id] = "Rs. #{funding_line.funding_line_money_amount}"
    end
    result
  end
  
end