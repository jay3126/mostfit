module Highmark

  module Client
    
    # creates a row for a client per highmarks pipe delimited format 
    def row_to_delimited_file(datetime = DateTime.now)
      return ["CRDRQINQR", "JOIN", "", "ACCT-ORIG", "", "PRE-DISB", datetime.strftime("%d-%m-%Y %H:%M:%S"), self.name]
    end

  end

  module Loan

    def to_highmark_xml
    end

  end

end
