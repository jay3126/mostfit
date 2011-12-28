class CreditBureauRequest
  include DataMapper::Resource
  
  property :id, Serial
  property :datetime, DateTime
  #property :request, String

  belongs_to :loan
  belongs_to :client

end

class HighmarkRequest < CreditBureauRequest

  def request_bulk(loan_selection_hash = {}, bureau = "highmark")
    selection = {"#{bureau}_done".to_sym => false}.merge(loan_selection_hash)
    @inquiry_data = Loan.all(selection).each{|l| l.send("to_#{bureau}_xml")}
    # f = File.open(filename, "w")
    # x = Builder::XmlMarkup.new(:target => f, :indent => 1)
    # x.tag! 'REQUEST-REQUEST-FILE'do
    #   x.tag! 'HEADER-SEGMENT' do
    #     x.tag! 'PRODUCT-TYP'("OVERLAP")
    #     x.tag! 'PRODUCT-VER'("1.0")
    #     x.tag! 'REQ-MBR'("MFI")
    #     x.tag! 'SUB-MBR-ID'("")
    #     x.tag! 'INQ-DT-TM'("30-08-2011")
    #     x.tag! 'REQ-VOL-TYP'("BULK")
    #     x.tag! 'REQ-ACTN-TYP'("SUBMIT")
    #     x.tag! 'TEST-FLG'("HMTEST")
    #     x.tag! 'USER-ID'("")
    #     x.PWD("U")
    #   end
    # end

  end

  def individual_client(client)
    # block_of_code = Proc.new do
      
    # end
  end

  def response_bulk
    
  end

end
