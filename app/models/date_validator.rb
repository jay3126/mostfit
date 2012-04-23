module DateValidator

  def self.screen_dates(dates_ary, on_or_after_date, before_date)
    screened_dates = dates_ary.select { |date|
      (date >= on_or_after_date) and (date < before_date)
    }
    screened_dates.sort
  end
    
end
