class CustomCalendar
  include DataMapper::Resource
  include Constants::Space
  include Constants::Properties
  include Pdf::CsvRead

  property :id,                 Serial
  property :on_date,            *DATE_NOT_NULL
  property :collection_date,    *DATE
  property :holiday_name,       String
  property :performed_by,       *INTEGER_NOT_NULL
  property :recorded_by,        *INTEGER_NOT_NULL
  property :updated_at,         *UPDATED_AT
  property :created_at,         *CREATED_AT
  property :deleted_at,         *DELETED_AT

  def self.save_custom_calendar(performed_by_id, recorded_by_id, year = Date.today.year.to_s, data = {})
    data.each do |s_no, data_values|
      collection_dates = data_values['collection date'].blank? ? [''] : data_values['collection date'].split('/')
      collection_dates.each do |collection_date|
        attr = {}
        attr[:collection_date] = Date.parse(collection_date+"-#{year}") unless collection_date.blank?
        attr[:on_date]         = Date.parse(data_values['normal date']+"-#{year}") unless data_values['normal date'].blank?
        attr[:holiday_name]    = data_values['holiday']
        attr[:recorded_by]     = recorded_by_id
        attr[:performed_by]    = performed_by_id
        first_or_create(attr)
      end
    end
  end
end