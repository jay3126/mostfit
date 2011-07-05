class CommonDataFormat < Report
  require 'csv'
  
  attr_accessor :from_date, :to_date, :branch, :branch_id, :center, :center_id
  
  include Mostfit::Reporting
  
  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today - 7
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    # @date = (dates and dates[:date]) ? dates[:date] : Date.today
    @name   = "Report from #{@from_date} to #{to_date}"
    get_parameters(params, user)
  end
  
  def name
    "Common Data Format Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Common Data Format Report"
  end
  
  def generate
    if @branch
      @grouper = @center
    else
      @grouper = @branch
    end
    
    # specifications as required by the common data format    
    gender = {
      :female   => "F", 
      :male     => "M", 
      :untagged => "U"
    }

    marital_status = {
      :married   => "M01", 
      :separated => "M02", 
      :divorced  => "M03", 
      :widowed   => "M04", 
      :unmarried => "M05", 
      :untagged  => "M06"
    }
    
    key_person_relationship = {
      :father          => "K01",
      :husband         => "K02",
      :mother          => "K03",
      :son             => "K04",
      :daughter        => "K05",
      :wife            => "K06",
      :brother         => "K07",
      :mother_in_law   => "K08",
      :father_in_law   => "K09",
      :daughter_in_law => "K10",
      :sister_in_law   => "K11",
      :son_in_law      => "K12",
      :brother_in_law  => "K13",
      :other           => "K14"
    }
    
    phone = {
      :residence => "P01",
      :company   => "P02",
      :mobile    => "P03",
      :permanent => "P04",
      :other     => "P05",
      :untagged  => "P06"
    }

    asset_ownership_indicator = {
      :yes => "Y",
      :no  => "N"
    }

    religion = {
      'hindu'       => "R01",
      'muslim'      => "R02",
      'christian'   => "R03",
      'sikh'        => "R04",
      'buddhist'    => "R05",
      'jain'        => "R06",
      'bahai'       => "R07",
      'others'      => "R08",
      ''            => "R10"
    }
    
    group_leader_indicator = {
      :yes      => "Y",
      :no       => "N",
      :untagged => "U"
    }
    
    center_leader_indicator = {
      :yes      => "Y",
      :no       => "N",
      :untagged => "U"
    }

    loan_category = {
      :jlg_group      => "TO1",
      :jlg_individual => "TO2",
      :individual     => "TO3"
    }
    
    # account status is nothing but loan status
    account_status = {
      :applied_in_future => "S01", #loan submitted
      :pending_approval  => "S01", #loan submitted
      :approved          => "S02", #loan_approved_not_yet_disbursed
      :rejected          => "S03", #loan_declined
      :disbursed         => "S04", #current
      :outstanding       => "S04", #current
      :delinquent        => "S05", #delinquent
      :written_off       => "S06", #written_off
      :claim_settlement  => "S06", #written_off
      :repaid            => "S07", #account_closed
      :preclosed         => "S07"  #account_closed
    }
    
    repayment_frequency = {
      :weekly              => "F01",  
      :biweekly            => "F02",
      :monthly             => "F03",
      :bimonthly           => "F04",
      :quarterly           => "F05",
      :semi_annually       => "F06",
      :annually            => "F07",
      :single_payment_loan => "F08",
      :other               => "F10"
    } 

    write_off_reason = { 
      :first_payment_default             => "X01",
      :death                             => "X02",
      :willful_default_status            => "X03",
      :suit_filed_willful_default_status => "X04", 
      :untagged                          => "X05",
      :not_applicable                    => "X06"
    }

    days_past_due = {
      :zero_payments_past_due => "000",
      :no_payment_history_available_for_this_month => "XXX",
    }
    
    insurance_indicator = {
      true      => "Y",
      false     => "N"
    }
    
    type_of_insurance = {
      :life_insurance            => "L01", 
      :credit_insurance          => "L02",
      :health_medical_insurance  => "L03",
      :property_insurance        => "L04",
      :liability_insurance       => "L05",
      :other                     => "L10"
    }

    meeting_day_of_the_week = {
      :monday     => "MON",
      :tuesday    => "TUE",
      :wednesday  => "WED",
      :thursday   => "THU",
      :friday     => "FRI",
      :saturday   => "SAT",
      :sunday     => "SUN"
    }
    
    states = {
      :andhra_pradesh     => "AP",
      :arunachal_pradesh  => "AR",
      :assam              => "AS",
      :bihar              => "BR",
      :chattisgarh        => "CG",
      :goa                => "GA",
      :gujarat            => "GJ",
      :haryana            => "HR",
      :himachal_pradesh   => "HP",
      :jammu_kashmir      => "JK",
      :jharkhand          => "JH",
      :karnataka          => "KA",
      :kerala             => "KL",
      :madhya_pradesh     => "MP",
      :maharashtra        => "MH",
      :manipur            => "MN",
      :meghalaya          => "ML",
      :mizoram            => "MZ",
      :nagaland           => "NL",
      :orissa             => "OR",
      :punjab             => "PB",
      :rajasthan          => "RJ",
      :sikkim             => "SK",
      :tamil_nadu         => "TN",
      :tripura            => "TR",
      :uttarakhand        => "UK",
      :uttar_pradesh      => "UP",
      :west_bengal        => "WB",
      :andaman_nicobar    => "AN",
      :chandigarh         => "CH",
      :dadra_nagar_haveli => "DN",
      :daman_diu          => "DD",
      :delhi              => "DL",
      :lakshadweep        => "LD",
      :pondicherry        => "PY"
    }
    
    branches, centers, clients = {}, {}, {}
    @data = []
    
    # data["CNSCRD"]||= {}
    # data["ADRCRD"]||= {}
    # data["ACTCRD"]||= {}    
    
    @grouper.each do |g|
      loans = g.loans(:applied_on.gte => @from_date, :applied_on.lte => @to_date)
      unless loans.empty? 
        loans.each do |l|
          client = l.client
          @data << ["CNSCRD".rjust(6),
                    client.id.to_s.rjust(35), 
                    client.center.branch.id.to_s.rjust(30), 
                    client.center.id.to_s.rjust(30),
                    client.client_group.id.to_s.rjust(20),
                    client.name.rjust(100),
                    "".rjust(50),
                    "".rjust(50),
                    "".rjust(30),
                    client.date_of_birth.strftime("%d%m%Y").rjust(8),
                    (client.date_joined -  client.date_of_birth).to_s.rjust(3),
                    client.date_joined.strftime("%d%m%Y").rjust(8),
                    (client.respond_to?(:gender) ? client.send(:gender) : gender[:female]).rjust(1), # ideally it should be untagged
                    (client.spouse_name.empty? ? marital_status[:untagged] : marital_status[:married]),
                    client.spouse_name.rjust(100),
                    (client.spouse_name.empty? ? key_person_relationship[:other] : marital_status[:husband]),
                    "".rjust(100), #member 1
                    "".rjust(3), #relationship with member 1
                    "".rjust(100), #member 2
                    "".rjust(3), #relationship with member 1
                    "".rjust(100), #member 3
                    "".rjust(3), #relationship with member 1
                    "".rjust(100), #member 4
                    "".rjust(3), #relationship with member 1
                    "".rjust(100), #nominee name
                    "".rjust(3), #nominee relationship
                    "".rjust(3), #nominee age
                    "".rjust(20), #voters id
                    "".rjust(40), # UID
                    "".rjust(15), #PAN
                    "".rjust(20), #ration card
                    "".rjust(20), #other id type description 1
                    "".rjust(30), #other id 1
                    "".rjust(20), #other id type description 2
                    "".rjust(30), #other id 2
                    "".rjust(20), #other id type description 3
                    "".rjust(30), #other id 3
                    phone[:untagged], #telephone number type 1
                    "".rjust(15), #telephone number 1
                    phone[:untagged], #telephone number type 2
                    "".rjust(15), #telephone number 2
                    client.poverty_status.to_s.rjust(20),
                    ((client.other_productive_asset.nil? || client.other_productive_asset.empty?) ? asset_ownership_indicator[:no] : asset_ownership_indicator[:yes]),
                    "", #client. #number of dependents
                    client.bank_name.to_s.rjust(50),
                    client.bank_branch.to_s.rjust(50),
                    client.account_number.to_s.rjust(35),
                    (client.occupation.nil? ? "" : client.occupation.name).rjust(50),
                    client.total_income.to_s.rjust(9),
                    "".rjust(9), #expenditure
                    religion[client.religion],
                    client.caste.rjust(30),
                    group_leader_indicator[:untagged],
                    center_leader_indicator[:untagged],
                    "".rjust(30), #dummy reserved for future use
                    "ADRCRD",  
                    client.address.rjust(200), #permanent address
                    "".rjust(2), #state code
                    "".rjust(10), #pin code
                    client.address.rjust(200), #present address
                    "".rjust(2), #state code
                    "".rjust(10), #pin code
                    "".rjust(30), #dummy reserved for future use
                    "ACTCRD",
                    l.id.to_s.rjust(35),
                    l.id.to_s.rjust(35),
                    client.center.branch_id.to_s.rjust(30),
                    client.center_id.to_s.rjust(30),
                    l.applied_by.name.rjust(30),
                    "".rjust(8),
                    "".rjust(3), #loan category
                    client.client_group.id.to_s.rjust(20),
                    l.cycle_number.to_s.rjust(30),
                    l.occupation.name.rjust(20),  #purpose
                    account_status[l.get_status],
                    l.applied_on.strftime("%d%m%Y").rjust(8),
                    l.approved_on.strftime("%d%m%Y").rjust(8),
                    (l.disbursal_date.nil? ? l.disbursal_date.strftime("%d%m%Y").rjust(8) : "".rjust(8)),
                    l.scheduled_maturity_date.strftime("%d%m%Y").rjust(8), #loan closed
                    l.loan_history.last.date.strftime("%d%m%Y").rjust(8),
                    l.amount_applied_for.to_currency.rjust(9),
                    l.amount_sanctioned.to_currency.rjust(9), #amount approved or sanctioned
                    l.amount.to_currency.rjust(9), #amount disbursed
                    l.number_of_installments.to_s.rjust(3), #number of installments
                    l.installment_frequency.to_s.rjust(3), #repayment frequency
                    (l.payment_schedule[@to_date].nil? ? "" : l.payment_schedule[@to_date].amount.to_currency).rjust(9),   #installment amount / minimum amount due
                    l.actual_outstanding_total_on(@to_date).to_currency.rjust(9), #current balance
                    "".rjust(9), #amount overdue
                    "".rjust(3), #days past due
                    "".rjust(9), #write off amount
                    "".rjust(8), #date written off
                    "".rjust(20), #write-off reason
                    "".rjust(3), #no of meetings held
                    "".rjust(3), #no of meetings missed
                    insurance_indicator[(not l.insurance_policy.nil?)], #insurance indicator
                    "".rjust(3), #type of insurance
                    (l.insurance_policy.nil? ? "".rjust(10) : l.insurance_policy.premium.to_currency.rjust(10)), #sum assured / coverage
                    meeting_day_of_the_week[client.center.meeting_day].to_s.rjust(3), #meeting day of the week
                    client.center.meeting_time.rjust(5), #meeting time of the day
                    "".rjust(30) #dummy reserved for future use
                   ]
        end
      end
    end
    return @data
  end
  
  def get_csv(data)
    folder = File.join(Merb.root, "doc", "csv", "reports", self.name)
    FileUtils.mkdir_p(folder)
    filename = File.join(folder, "report_#{self.id}_from_#{@from_date}_to_#{to_date}_.csv")
    file = File.new(filename, "w")
    CSV::Writer.generate(file) do |csv|
      data.each do |datum|
        csv << datum
      end
    end
    return file
  end
end
