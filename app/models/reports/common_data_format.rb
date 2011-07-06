class CommonDataFormat < Report
  
  attr_accessor :from_date, :to_date, :branch, :branch_id, :center, :center_id
  
  include Mostfit::Reporting
  include Csv::CommonDataCSV
  
  def initialize(params, dates, user)
    @from_date = (dates and dates[:from_date]) ? dates[:from_date] : Date.today << 1
    @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
    @name   = "Report from #{@from_date} to #{@to_date}"
    get_parameters(params, user)
  end
  
  def name
    "Common Data Format Report from #{@from_date} to #{@to_date}"
  end
  
  def self.name
    "Common Data Format Report"
  end
  
  def generate
    @data = []
    @data << ["Segment Identifier",
              "Member Identifier",
              "Branch Identifier",
              "Kendra/Centre Identifier",
              "Group Identifier",
              "Member Name 1",
              "Member Name 2",
              "Member Name 3",
              "Alternate Name of Member",
              "Member Birth Date",
              "Member Age",
              "Member's age as on date",
              "Member Gender Type",
              "Marital Status Type",
              "Key Person's name",
              "Key Person's relationship",
              "Member relationship Name 1",
              "Member relationship Type 1",
              "Member relationship Name 2",
              "Member relationship Type 2",
              "Member relationship Name 3",
              "Member relationship Type 3",
              "Member relationship Name 4",
              "Member relationship Type 4",
              "Nominee Name",
              "Nominee relationship",
              "Nominee Age",
              "Voter's ID",
              "UID",
              "PAN",
              "Ration Card",
              "Member Other ID 1 Type description",
              "Member Other ID 1",
              "Member Other ID 2 Type description",
              "Member Other ID 2 ",
              "Member Other ID 3 Type description",
              "Member Other ID 3",
              "Telephone Number 1 type Indicator",
              "Member Telephone Number 1",
              "Telephone Number 2 type Indicator",
              "Member Telephone Number 2",
              "Poverty Index",
              "Asset ownership indicator",
              "Number of Dependents",
              "Bank Account - Bank Name",
              "Bank Account - Branch Name",
              "Bank Account - Account Number",
              "Occupation",
              "Total Monthly Family Income",
              "Monthly Family Expenses",
              "Member's Religion",
              "Member's Caste",
              "Group Leader indicator",
              "Center Leader indicator",
              "Dummy",
              "Segment Identifier",
              "Member's Permanent Address",
              "State Code ( Permanent Address)",
              "Pin Code ( Permanent Address)",
              "Member's Current Address",
              "State Code ( Current Address)",
              "Pin Code ( Current Address)",
              "Dummy",
              "Segment Identifier",
              "Unique Account Refernce number",
              "Account Number",
              "Branch Identifier",
              "Kendra/Centre Identifier",
              "LoA/N Officer for Originating the loan",
              "Date of Account Information",
              "Loan Category",
              "Group Identifier",
              "Loan Cycle-id",
              "Loan Purpose",
              "Account Status ",
              "Application date",
              "Sanctioned Date",
              "Date Opened/Disbursed",
              "Date Closed (if closed)",
              "Date of last payment",
              "Applied For amount",
              "Loan amount Sanctioned",
              "Total Amount Disbursed (Rupees)",
              "Number of Installments",
              "Repayment Frequency",
              "Minimum Amt Due/Instalment Amount",
              "Current Balance (Rupees)",
              "Amount Overdue (Rupees)",
              "DPD (Days past due)",
              "Write Off Amount (Rupees)",
              "Date Write-Off (if written-off)",
              "Write-off reason (if written off)",
              "No. of meetings held",
              "No. of meetings missed",
              "Insurance Indicator",
              "Type of Insurance",
              "Sum Assured/Coverage",
              "Agreed meeting day of the week",
              "Agreed Meeting time of the day",
              "Dummy"
             ]
    
    (if @branch
       Loan.all("client.center.id" => @center.map{|c| c.id}, :applied_on.gte => @from_date, :applied_on.lte => @to_date)
     else
       Loan.all("client.center.branch.id" => @branch.map{|b| b.id}, :applied_on.gte => @from_date, :applied_on.lte => @to_date)
     end
     ).each do |l|
      client = l.client
      center = client.center
      branch = center.branch
      lh     = LoanHistory.first(:loan_id => l.id, :date.lte => Date.today, :status => [:disbursed, :outstanding], :order => [:date.desc])
      
      @data << ["CNSCRD".rjust(6),
                client.id.to_s.rjust(35), 
                branch.id.to_s.rjust(30), 
                center.id.to_s.rjust(30),
                client.client_group_id.to_s.rjust(20),
                client.name.rjust(100),
                "".rjust(50),
                "".rjust(50),
                "".rjust(30),
                client.date_of_birth.strftime("%d%m%Y").rjust(8),
                (client.date_joined.year -  client.date_of_birth.year).to_s.rjust(3),
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
                client.reference.rjust(30), #other id 1
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
                client.number_of_family_members.to_s.rjust(2), #number of dependents
                client.bank_name.to_s.rjust(50),
                client.bank_branch.to_s.rjust(50),
                client.account_number.to_s.rjust(35),
                (client.occupation.nil? ? "" : client.occupation.name).rjust(50),
                client.total_income.to_s.rjust(9),
                "".rjust(9), #expenditure
                religion[client.religion],
                client.caste.rjust(30),
                group_leader_indicator[:untagged],
                (CenterLeader.first(:client_id => client.id).nil? ? center_leader_indicator[:no] : center_leader_indicator[:yes]),
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
                branch.id.to_s.rjust(30),
                client.center_id.to_s.rjust(30),
                l.applied_by.name.rjust(30),
                "".rjust(8),
                loan_category[:jlg_individual].rjust(3), #loan category
                client.client_group_id.to_s.rjust(20),
                l.cycle_number.to_s.rjust(30),
                l.occupation.name.rjust(20),  #purpose
                account_status[l.get_status],
                l.applied_on.strftime("%d%m%Y").rjust(8),
                l.approved_on.strftime("%d%m%Y").rjust(8),
                (l.disbursal_date.nil? ? l.scheduled_disbursal_date : l.disbursal_date).strftime("%d%m%Y").rjust(8),
                ((l.status == :repaid and lh.status == :repaid) ? lh.date.strftime("%d%m%Y") : "").rjust(8), #loan closed
                lh.date.strftime("%d%m%Y").rjust(8), #loan closed
                l.amount_applied_for.to_currency.rjust(9),
                l.amount_sanctioned.to_currency.rjust(9), #amount approved or sanctioned
                l.amount.to_currency.rjust(9), #amount disbursed
                l.number_of_installments.to_s.rjust(3), #number of installments
                l.installment_frequency.to_s.rjust(3), #repayment frequency
                (l.payment_schedule[@to_date].nil? ? "" : l.payment_schedule[@to_date][:total].to_currency).rjust(9),   #installment amount / minimum amount due
                lh.actual_outstanding_total.to_currency.rjust(9),
                lh.amount_in_default.to_currency.rjust(9), #amount overdue
                lh.days_overdue.to_s.rjust(3), #days past due
                "".rjust(9), #write off amount
                (l.written_off_on.nil? ? "" : l.written_off_on.strftime("%d%m%Y")).rjust(8), #date written off
                "".rjust(20), #write-off reason
                Attendance.all(:client_id => client.id, :center_id => center.id).count.to_s.rjust(3), #no of meetings held
                Attendance.all(:client_id => client.id, :center_id => center.id, :status => "absent").count.to_s.rjust(3), #no of meetings missed
                insurance_indicator[(not l.insurance_policy.nil?)], #insurance indicator
                "".rjust(3), #type of insurance
                (l.insurance_policy.nil? ? "".rjust(10) : l.insurance_policy.premium.to_currency.rjust(10)), #sum assured / coverage
                meeting_day_of_the_week[center.meeting_day].to_s.rjust(3), #meeting day of the week
                center.meeting_time.rjust(5), #meeting time of the day
                "".rjust(30) #dummy reserved for future use
               ]
    end
    return @data
  end
  
  private
    
  # specifications as required by the common data format    
  def gender
    @gender ||= {
      :female   => "F", 
      :male     => "M", 
      :untagged => "U"
    }
  end

  def marital_status
    @marital_status ||= {
      :married   => "M01", 
      :separated => "M02", 
      :divorced  => "M03", 
      :widowed   => "M04", 
      :unmarried => "M05", 
      :untagged  => "M06"
    }
  end
    
  def key_person_relationship
    @key_person_relationship ||= {
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
  end
  
  def phone
    @phone ||= {
      :residence => "P01",
      :company   => "P02",
      :mobile    => "P03",
      :permanent => "P04",
      :other     => "P05",
      :untagged  => "P06"
    }
  end
  
  def asset_ownership_indicator
    @asset_ownership_indicator ||= {
      :yes => "Y",
      :no  => "N"
    }
  end

  def religion
    @religion ||= {
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
  end


  def group_leader_indicator
    @group_leader_indicator ||= {
      :yes      => "Y",
      :no       => "N",
      :untagged => "U"
    }
  end

  def center_leader_indicator
    @center_leader_indicator ||= {
      :yes      => "Y",
      :no       => "N",
      :untagged => "U"
    }
  end

  def loan_category
    @loan_category ||= {
      :jlg_group      => "TO1",
      :jlg_individual => "TO2",
      :individual     => "TO3"
    }
  end
    
    # account status is nothing but loan status
  def account_status
    @account_status ||= {
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
  end

  def repayment_frequency
    @repayment_frequency ||= {
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
  end

  def write_off_reason
    @write_off_reason = { 
      :first_payment_default             => "X01",
      :death                             => "X02",
      :willful_default_status            => "X03",
      :suit_filed_willful_default_status => "X04", 
      :untagged                          => "X05",
      :not_applicable                    => "X06"
    }
  end

  def days_past_due
    @days_past_due ||= {
      :zero_payments_past_due => "000",
      :no_payment_history_available_for_this_month => "XXX",
    }
  end
   
  def insurance_indicator
    @insurance_indicator ||= {
      true      => "Y",
      false     => "N"
    }
  end
    
  def type_of_insurance
    @type_of_insurance ||= {
      :life_insurance            => "L01", 
      :credit_insurance          => "L02",
      :health_medical_insurance  => "L03",
      :property_insurance        => "L04",
      :liability_insurance       => "L05",
      :other                     => "L10"
    }
  end

  def meeting_day_of_the_week
    @meeting_day_of_the_week ||= {
      :monday     => "MON",
      :tuesday    => "TUE",
      :wednesday  => "WED",
      :thursday   => "THU",
      :friday     => "FRI",
      :saturday   => "SAT",
      :sunday     => "SUN"
    }
  end
    
  def states
    @states ||= {
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
  end
end
