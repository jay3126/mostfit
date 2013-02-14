module Highmark
  
  class CommonDataFormat < Report
    
    attr_accessor :from_date, :to_date 
    
    include Mostfit::Reporting
    
    def initialize(params, dates, user)
      @to_date   = (dates and dates[:to_date]) ? dates[:to_date] : Date.today
      @from_date = (dates and dates[:from_date]) ? dates[:from_date] : @to_date << 3
      @frequency_identifier = params[:frequency_identifier]
      get_parameters(params, user)
    end
    
    def name
      "Common Data Format Report for #{Mfi.first.name} from #{@from_date} to #{@to_date}"
    end
    
    def self.name
      "Common Data Format Report"
    end
    
    def generate
      @data = { "CNSCRD" => [], "ADRCRD" => [], "ACTCRD" => [], "BRNCRD" => [] }
      folder = File.join(Merb.root, "doc", "csv", "reports")      
      FileUtils.mkdir_p(folder)

      filename_cnscrd = File.join(folder, "#{self.name}-customer.csv")
      filename_adrcrd = File.join(folder, "#{self.name}-address.csv")
      filename_actcrd = File.join(folder, "#{self.name}-accounts.csv")
      filename_brncrd = File.join(folder, "#{self.name}-branch-center-list.csv")

      File.new(filename_cnscrd, "w").close
      File.new(filename_adrcrd, "w").close
      File.new(filename_actcrd, "w").close
      File.new(filename_brncrd, "w").close

      attendance_record = BizLocation.all("location_level.level" => 0).map{|x| [x.id, AttendanceRecord.all(:at_location => x.id, :counterparty_type => :client).aggregate(:counterparty_id, :counterparty_id.count).to_hash]}.to_hash
      absent_record = attendance_record = BizLocation.all("location_level.level" => 0).map{|x| [x.id, AttendanceRecord.all(:at_location => x.id, :counterparty_type => :client, :attendance => :absent_attendance_status).aggregate(:counterparty_id, :counterparty_id.count).to_hash]}.to_hash
     
      append_to_file_as_csv([headers["CNSCRD"]], filename_cnscrd)
      append_to_file_as_csv([headers["ADRCRD"]], filename_adrcrd)
      append_to_file_as_csv([headers["ACTCRD"]], filename_actcrd)
      append_to_file_as_csv([headers["BRNCRD"]], filename_brncrd)

      # REPAID, WRITTEN_OFF AND PRECLOSED loans are treated as closed loans
      all_loans = Lending.all(:fields => [:id]).map{|x| x.id}.uniq
      all_disbursed_loans_during_period = Lending.all(:disbursal_date.gte => @from_date, :disbursal_date.lte => @to_date, :fields => [:id]).map{|x| x.id}.uniq
      loans_with_status_changes_during_period = LoanStatusChange.all(:from_status => :disbursed_loan_status, :to_status => [:repaid_loan_status, :preclosed_loan_status, :written_off_loan_status], :effective_on.gte => @from_date, :effective_on.lte => @to_date).map{|x| x.lending_id}.uniq
      cut_off_date = @from_date
      ineligible_written_off_loans = Lending.all(:status => :written_off_loan_status, :write_off_on_date.lte => cut_off_date).map{|x| x.id}.uniq
      ineligible_preclosed_loans = Lending.all(:status => :preclosed_loan_status, :preclosed_on_date.lte => cut_off_date).map{|x| x.id}.uniq
      ineligible_repaid_loans = Lending.all(:status => :repaid_loan_status, :repaid_on_date.lte => cut_off_date).map{|x| x.id}.uniq

      #this is done as per Suryoday's requirements. For monthly submission only those new_disbursements + status changes loans are required and for monthly all loans.
      if @frequency_identifier == 'weekly'
        eligible_loans = (all_disbursed_loans_during_period + loans_with_status_changes_during_period) - (ineligible_written_off_loans + ineligible_preclosed_loans + ineligible_repaid_loans)
      elsif @frequency_identifier == 'monthly'
        eligible_loans = all_loans - (ineligible_written_off_loans + ineligible_preclosed_loans + ineligible_repaid_loans)
      end

      eligible_loans.each do |l_id|
        begin
          loan = Lending.get(l_id)
          client = loan.borrower
          center = BizLocation.get(loan.administered_at_origin)
          branch = BizLocation.get(loan.accounted_at_origin)
          meetings = MeetingCalendar.last(:location_id => center.id, :on_date.lte => @to_date)

          rows = row(loan, client, center, branch, attendance_record, absent_record, meetings)
          
          #the following lines of code replace the blanks with nils
          rows["CNSCRD"].map!{|x| x = (x == "" ? nil : x)}
          rows["ADRCRD"].map!{|x| x = (x == "" ? nil : x)}
          rows["ACTCRD"].map!{|x| x = (x == "" ? nil : x)}
          rows["BRNCRD"].map!{|x| x = (x == "" ? nil : x)}

          unless @data["CNSCRD"].include?(rows["CNSCRD"])
            @data["CNSCRD"] << rows["CNSCRD"]
            append_to_file_as_csv([rows["CNSCRD"]], filename_cnscrd)
            append_to_file_as_csv([rows["ADRCRD"]], filename_adrcrd)
          end
          append_to_file_as_csv([rows["ACTCRD"]], filename_actcrd)
          append_to_file_as_csv([rows["BRNCRD"]], filename_brncrd)
        rescue
          puts "ERROR: loan_id: #{l_id}"
        end
      end
      
      return true
    end
    
    private

    def append_to_file_as_csv(data, filename)
      FasterCSV.open(filename, "a", {:col_sep => "|"}) do |csv|
        data.each do |datum|
          csv << datum
        end
      end
    end
    
    def headers
      _headers ||= { 
        "CNSCRD" => ["Bank ID",
                     "Segment Identifier",
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
                     "Member Name 4",
                     "Member Name 5",
                     "Passport Number",
                     "Parent ID",
                     "EXTRACTION FILE ID",
                     "SEVERITY"],
        "ADRCRD" => ["Bank ID",
                     "Segment Identifier",
                     "Member's Permanent Address",
                     "State Code ( Permanent Address)",
                     "Pin Code ( Permanent Address)",
                     "Member's Current Address",
                     "State Code ( Current Address)",
                     "Pin Code ( Current Address)",
                     "Dummy",
                     "Parent ID",
                     "EXTRACTION FILE ID",
                     "SEVERITY"],
        "ACTCRD" => ["Bank ID",
                     "Segment Identifier",
                     "Unique Account Reference number",
                     "Account Number",
                     "Branch Identifier",
                     "Kendra/Centre Identifier",
                     "Loan Officer for Originating the loan",
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
                     "Dummy",
                     "Old Member Code", #in case the member id  number has changed
                     "Old Member Short Number", #NULL
                     "Old Account Number", # in case the account number has changed
                     "CIBIL Act Status", # has to be populated 
                     "Asset Classification", #if the account is doubtful, or if the loan is not being paid regularly
                     "Member Code", # NULL
                     "Member Short Number", #NULL
                     "Account Type", #NULL
                     "Ownership Indicator", #NULL
                     "Parent ID", 
                     "EXTRACTION FILE ID", 
                     "SEVERITY"],
        "BRNCRD" => ["Branch Code",
                     "Branch Name",
                     "Center Id",
                     "Center Name",
                     "Center Address 1",
                     "Center Address 2",
                     "Center Address 3",
                     "Center Pincode"]
      }
    end
    
    def row(loan, client, center, branch, attendance_record, absent_record, meetings)
      _row = {
        "CNSCRD" => [client.client_identifier.to_s.truncate(100, ""), #bank id
                     "CNSCRD", # segment identifier
                     client.client_identifier.to_s.truncate(35, ""), # member identifier
                     branch.biz_location_identifier.to_s.truncate(30, ""), # branch identifier
                     center.biz_location_identifier.to_s.truncate(30, ""), # center / kendra identifier
                     client.client_group_id.to_s.truncate(20, ""), # client group identifier
                     client.name.truncate(100, ""), # member name
                     nil, # member name 2
                     nil, # member name 3
                     nil, # alternate name of member
                     (client.date_of_birth ? client.date_of_birth.strftime("%d%m%Y").truncate(8,"") : nil), #member's date of birth
                     ((client.date_joined and client.date_of_birth) ? (client.date_joined.year - client.date_of_birth.year).to_s.truncate(3, "") : nil), # member's age on date
                     (client.date_joined ? client.date_joined.strftime("%d%m%Y").truncate(8,"") : nil),
                     ((client.gender == :gender_not_specified) ? gender_value[:untagged] : gender_value[client.gender]), # client gender
                     ((client.marital_status == 'Single') ? marital_status_value[:untagged] : marital_status_value[client.marital_status.downcase.to_sym]), #marital status
                     client.spouse_name.truncate(100, ""),
                     key_person_relationship(client, 'spouse'),
                     nil, #member 1
                     nil, #relationship with member 1
                     nil, #member 2
                     nil, #relationship with member 2
                     nil, #member 3
                     nil, #relationship with member 3
                     nil, #member 4
                     nil, #relationship with member 4
                     client.guarantor_name.truncate(100, ""), #nominee name
                     key_person_relationship(client, client.guarantor_relationship.downcase), #nominee relationship
                     ((client.date_joined and client.guarantor_dob) ? (client.date_joined.year - client.guarantor_dob.year).to_s.truncate(3, "") : nil), #nominee age
                     (client.reference2_type == :voter_id ? client.reference2.truncate(20, "") :  nil), #voters id
                     (client.reference2_type == :uid ? client.reference2.truncate(15, "") : nil), # UID
                     (client.reference2_type == :pan_card ? client.reference2.truncate(15, "") : nil), #PAN
                     (client.reference_type == :ration_card ? client.reference.truncate(20, "") : nil), #ration card
                     nil, #other id type description 1
                     nil, #other id 1
                     nil, #other id type description 2
                     nil, #other id 2
                     nil, #other id type description 3
                     nil, #other id 3
                     phone[client.telephone_type.downcase.to_sym], #telephone number type 1
                     (client.telephone_number.nil? ? nil : client.telephone_number.truncate(15, "")), #telephone number 1
                     nil, #telephone number type 2
                     nil, #telephone number 1
                     client.poverty_status.to_s.truncate(20, ""), #poverty index
                     nil, #asset ownership indicator
                     nil, #number of dependents
                     nil, #bank account - bank name
                     nil, #bank account - branch name
                     nil, #bank account - account number
                     (client.occupation.nil? ? nil : client.occupation.name.truncate(50, "")), #occupation
                     client.total_income.to_s.truncate(9, ""), #total family income
                     nil, #expenditure
                     religion[client.religion.to_s], # religion
                     client.caste.to_s.truncate(30, ""), # caste
                     nil, # group leader identifier.
                     nil, # center leader identifier.
                     nil, #dummy reserved for future use
                     nil, #member name 4
                     nil, #member name 5
                     nil, #passport number
                     nil, #parent id
                     nil, # extraction file id
                     nil  # severity
                    ],
        "ADRCRD" => [client.client_identifier.to_s.truncate(100, ""),
                     "ADRCRD",  
                     client.address.gsub("\n", " ").gsub("\r", " ").truncate(200, ""), #permanent address
                     ((client.state and client.state.empty?) ? nil : states[client.state.downcase.to_sym]), #state code
                     client.pincode.to_s.truncate(100, ""), #pin code
                     nil, #present address
                     nil, #state code
                     nil, #pin code
                     nil, #dummy reserved for future use
                     client.id.to_s.truncate(100, ""), #parent id
                     nil, #extraction field id
                     nil #severity
                    ],
        "ACTCRD" => [client.client_identifier.to_s.truncate(100, ""),
                     "ACTCRD",
                     loan.id.to_s.truncate(35, ""),
                     loan.id.to_s.truncate(35, ""),
                     branch.biz_location_identifier.to_s.truncate(30, ""),
                     center.biz_location_identifier.to_s.truncate(30, ""),
                     StaffMember.get(loan.applied_by_staff).name.truncate(30, ""),
                     account_information_date(loan, loan.status).strftime("%d%m%Y").truncate(8,""), #date of account information
                     loan_category[:jlg_individual].truncate(3, ""), #loan category
                     client.client_group_id.to_s.truncate(20, ""),
                     loan.cycle_number.to_s.truncate(30, ""),
                     (loan.loan_purpose ? loan.loan_purpose.truncate(20, "") : nil),  #purpose
                     account_status[loan.status.to_s.chomp('_loan_status').to_sym],
                     (loan.applied_on_date ? loan.applied_on_date.strftime("%d%m%Y").truncate(8, "") : nil),
                     (loan.approved_on_date ? loan.approved_on_date.strftime("%d%m%Y").truncate(8, "") : nil),
                     (loan.disbursal_date.nil? ? loan.scheduled_disbursal_date : loan.disbursal_date).strftime("%d%m%Y").truncate(8, ""),
                     (account_information_date(loan, loan.status) == @to_date) ? nil : account_information_date(loan, loan.status).strftime("%d%m%Y").truncate(8, ""), #loan closed
                     (LoanReceipt.last(:lending_id => loan.id).nil? ? nil : LoanReceipt.last(:lending_id => loan.id).effective_on.strftime("%d%m%Y").truncate(8, "")), #loan closed
                     (loan.applied_amount ? ((MoneyManager.get_money_instance(Money.new(loan.applied_amount.to_i, :INR).to_s)).to_s.chomp(".00")).truncate(9, "") : nil),
                     (loan.approved_amount ? ((MoneyManager.get_money_instance(Money.new(loan.approved_amount.to_i, :INR).to_s)).to_s.chomp(".00")).truncate(9, "") : nil), #amount approved or sanctioned
                     (loan.disbursed_amount ? ((MoneyManager.get_money_instance(Money.new(loan.disbursed_amount.to_i, :INR).to_s)).to_s.chomp(".00")).truncate(9, "") : nil), #amount disbursed
                     loan.tenure.to_s.truncate(3, ""), #number of installments
                     repayment_frequency[loan.repayment_frequency], #repayment frequency
                     (loan.loan_installment_amount.to_s.chomp(".00").truncate(9, "")),   #installment amount / minimum amount due
                     loan.actual_total_outstanding_loan(@to_date).to_s.chomp(".00").truncate(9, ""),
                     ((loan.actual_total_outstanding_loan(@to_date) > loan.scheduled_total_outstanding(@to_date)) ? (loan.actual_total_outstanding_loan(@to_date) - loan.scheduled_total_outstanding(@to_date)).to_s.chomp(".00").truncate(9, "") : MoneyManager.default_zero_money.to_s.chomp(".00")), #amount overdue
                     (LoanDueStatus.overdue_day_on_date(loan.id, @to_date) > 999 ? 999 : LoanDueStatus.overdue_day_on_date(loan.id, @to_date)).to_s.truncate(3, ""), #days past due
                     (loan.status == :written_off_loan_status ? loan.actual_principal_outstanding(@to_date).to_s.chomp(".00") : nil), #write off amount
                     (loan.write_off_on_date.nil? ? nil : loan.write_off_on_date.strftime("%d%m%Y").truncate(8, "")), #date written off
                     nil, #write-off reason
                     attendance_record[center.id][client.id], #no of meetings held
                     absent_record[center.id][client.id], #no of meetings missed
                     insurance_indicator[(not loan.simple_insurance_policies.nil?)], #insurance indicator
                     (loan.simple_insurance_policies and (not loan.simple_insurance_policies.nil?) and loan.simple_insurance_policies.first.simple_insurance_product and (not loan.simple_insurance_policies.first.simple_insurance_product.nil?)) ? type_of_insurance[loan.simple_insurance_policies.first.simple_insurance_product.insured_type] : nil, #type of insurance
                     (loan.simple_insurance_policies and (not loan.simple_insurance_policies.nil?) and loan.simple_insurance_policies.simple_insurance_product and (not loan.simple_insurance_policies.simple_insurance_product.nil?)) ? ((MoneyManager.get_money_instance(Money.new(loan.simple_insurance_policies.first.simple_insurance_product.cover_amount.to_i, :INR).to_s).to_s.chomp(".00")).truncate(10, "")) : MoneyManager.default_zero_money.to_s.chomp(".00"), #sum assured / coverage
                     (meetings and (not meetings.nil?)) ? meeting_day_of_the_week[Constants::Time.get_week_day(meetings.actual_date)].to_s.truncate(3, "") : nil, #meeting day of the week
                     (meetings and (not meetings.nil?)) ? meetings.meeting_begins_at.truncate(8, "") : nil, #meeting time of the day
                     nil, #dummy reserved for future use
                     nil, #old member code
                     nil, #old member shrt number
                     nil, #old account number
                     nil, # cibil act status
                     nil, # asset classification
                     nil, # member code
                     nil, # member shrt number
                     nil, # account type
                     nil, #ownership indicator
                     client.id.to_s.truncate(100, ""), #parent id
                     nil, # extraction field id
                     nil  # severity
                    ],
        "BRNCRD" => [branch.id.to_s.truncate(100, ""), #branch code
                     branch.name.truncate(100, ""), #branch name
                     center.biz_location_identifier.to_s.truncate(30, ""),
                     center.name.truncate(100, ""), #center identifier
                     center.biz_location_address.gsub("\n", " ").gsub("\r", " ").truncate(200, ""), #center address 1
                     nil, #address 2
                     nil, # address 3
                     nil  # pin code.
                    ]
      }
    end
    
    # specifications as required by the common data format    
    def gender_value
      _gender ||= {
        :female   => "F", 
        :male     => "M", 
        :untagged => "U"
      }
    end

    def account_information_date(loan, status)
      if status == :repaid_loan_status
        return loan.repaid_on_date
      elsif status == :preclosed_loan_status
        return loan.preclosed_on_date
      elsif status == :written_off_loan_status
        return loan.write_off_on_date
      else
        return @to_date
      end
    end
    
    def marital_status_value
      _marital_status ||= {
        :married   => "M01", 
        :separated => "M02", 
        :divorced  => "M03", 
        :widowed   => "M04", 
        :unmarried => "M05", 
        :untagged  => "M06"
      }
    end
    
    def key_person_relationship(client, relationship)
      _key_person_relationship ||= {
        'father'          => "K01",
        'husband'         => "K02",
        'mother'          => "K03",
        'son'             => "K04",
        'adult_son'       => "K04",
        'daughter'        => "K05",
        'wife'            => "K06",
        'brother'         => "K07",
        'mother_in_law'   => "K08",
        'father_in_law'   => "K09",
        'daughter_in_law' => "K10",
        'sister_in_law'   => "K11",
        'son_in_law'      => "K12",
        'brother_in_law'  => "K13",
        'other'           => "K15",
      }   
      if relationship == 'spouse'
        return (client.gender == "female" ? _key_person_relationship['husband'] : _key_person_relationship['wife'])
      else
        return _key_person_relationship[relationship]
      end
    end
    
    def phone
      _phone ||= {
        :residence => "P01",
        :company   => "P02",
        :mobile    => "P03",
        :permanent => "P04",
        :other     => "P07",
        :untagged  => "P08"
      }
    end
    
    def asset_ownership_indicator
      _asset_ownership_indicator ||= {
        :yes => "Y",
        :no  => "N"
      }
    end
    
    def religion
      _religion ||= {
        'hindu'       => "R01",
        'muslim'      => "R02",
        'christian'   => "R03",
        'sikh'        => "R04",
        'buddhist'    => "R05",
        'jain'        => "R06",
        'bahai'       => "R07",
        'others'      => "R08",
        ''            => "R09"
      }
    end
    
    
    def group_leader_indicator
      _group_leader_indicator ||= {
        :yes      => "Y",
        :no       => "N",
        :untagged => "U"
      }
    end
    
    def center_leader_indicator
      _center_leader_indicator ||= {
        :yes      => "Y",
        :no       => "N",
        :untagged => "U"
      }
    end
    
    def loan_category
      _loan_category ||= {
        :jlg_group      => "T01",
        :jlg_individual => "T02",
        :individual     => "T03"
      }
    end
    
    # account status is nothing but loan status
    def account_status
      _account_status ||= {
        :applied_in_future => "S01", #loan submitted
        :pending_approval  => "S01", #loan submitted
        :approved          => "S02", #loan_approved_not_yet_disbursed
        :rejected          => "S03", #loan_declined
        :disbursed         => "S04", #current
        :outstanding       => "S04", #current
        :delinquent        => "S05", #delinquent
        :written_off       => "S06", #written_off
        :claim_settlement  => "S07", #account_closed
        :repaid            => "S07", #account_closed
        :preclosed         => "S07"  #account_closed
      }
    end
    
    def repayment_frequency
      _repayment_frequency ||= {
        :weekly              => "F01",  
        :biweekly            => "F02",
        :monthly             => "F03",
        :bimonthly           => "F04",
        :quarterly           => "F05",
        :semi_annually       => "F06",
        :annually            => "F07",
        :single_payment_loan => "F08",
        :other               => "F10",
        :quadweekly          => "F10"
      } 
    end
    
    def write_off_reason
      _write_off_reason = { 
        :first_payment_default             => "X01",
        :death                             => "X02",
        :willful_default_status            => "X03",
        :suit_filed_willful_default_status => "X04", 
        :untagged                          => "X09",
        :not_applicable                    => "X10"
      }
    end
    
    def days_past_due
      _days_past_due ||= {
        :zero_payments_past_due => "000",
        :no_payment_history_available_for_this_month => "XXX",
      }
    end
    
    def insurance_indicator
      _insurance_indicator ||= {
        true      => "Y",
        false     => "N"
      }
    end
    
    def type_of_insurance
      _type_of_insurance ||= {
        :life_insurance            => "L01", 
        :credit_insurance          => "L02",
        :health_medical_insurance  => "L03",
        :property_insurance        => "L04",
        :liability_insurance       => "L05",
        :other                     => "L10"
      }
    end
    
    def meeting_day_of_the_week
      _meeting_day_of_the_week ||= {
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
      _states ||= {
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
end
