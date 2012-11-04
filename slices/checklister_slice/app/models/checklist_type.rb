class ChecklistType
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :nullable => false
  property :created_at, DateTime, :nullable => false, :default => Date.today
  property :deleted_at, DateTime


  has n, :checklists

#---------------------------------------------------------------Destroy existing data---------------------------------------------------------------#
  def self.destroy_existing_data
    #deleting existing data
    ChecklistType.all.destroy
    Checklist.all.destroy
    Checkpoint.all.destroy
    CheckpointFilling.all.destroy
    Filler.all.destroy
    FreeText.all.destroy
    FreeTextFilling.all.destroy
    Response.all.destroy
    Section.all.destroy
    SectionType.all.destroy
    TargetEntity.all.destroy
    Dropdownpoint.all.destroy
    DropdownpointFilling.all.destroy

    Checkboxpoint.all.destroy
    CheckboxpointOptionFilling.all.destroy
    CheckboxpointOption.all.destroy


  end

#---------------------------------------------------------------existing data destroyed--------------------------------------------------------------#

#---------------------------------------------------------------Generate data for SCV---------------------------------------------------------------#

  def self.generate_scv_data
    #genarate data for surprise center visit:
    @checklist_type= ChecklistType.create!(:name => "Surprise Center Visit", :created_at => Date.today)
    @checklist=Checklist.create!(:name => "Surprise Center Visit.", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    #Data corresponding to section 1 in the sheet

    @section_type1=SectionType.create!(:name => "Surprise Center Visit", :created_at => Date.today)
    @section1=Section.create!(:section_type_id => @section_type1.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Surprise Centre Visit", :created_at => Date.today)
    @checkpoint1=Checkpoint.create!(:section_id => @section1.id, :name => "CONFIRM THAT LESS THAN 3 MEMBERS ARRIVED LATE", :sequence_number => 1, :created_at => Date.today)
    @checkpoint2=Checkpoint.create!(:section_id => @section1.id, :name => "CONFIRM THAT LESS THAN 3 MEMBERS WERE ABSENT", :sequence_number => 2, :created_at => Date.today)
    @checkpoint3=Checkpoint.create!(:section_id => @section1.id, :name => "CONFIRM THAT THE CENTER LEADER WAS PRESENT AT THE MEETING", :sequence_number => 3, :created_at => Date.today)
    @checkpoint4=Checkpoint.create!(:section_id => @section1.id, :name => "CONFIRM THAT THE CENTER MEMBERS FOLLOWED PROCEDURES", :sequence_number => 4, :created_at => Date.today)
    @checkpoint5=Checkpoint.create!(:section_id => @section1.id, :name => "CONFIRM THAT THE FIELD OFFICER FOLLOWED PROCEDURES", :sequence_number => 5, :created_at => Date.today)
    @checkpoint6=Checkpoint.create!(:section_id => @section1.id, :name => "CONFIRM THAT THE CENTER LEADER MAINTAINS UP-TO-DATE ATTENDANCE,REGISTERS AND RECEIPTS", :sequence_number => 6, :created_at => Date.today)
    @checkpoint7=Checkpoint.create!(:section_id => @section1.id, :name => "CONFIRM THAT THE PASSBOOKS AND CENTER FILE WERE UP-TO-DATE AND WITHOUT ANY DISCREPANCY", :sequence_number => 7, :created_at => Date.today)
    @checkpoint8=Checkpoint.create!(:section_id => @section1.id, :name => "CONFIRM THAT NO MEMBER PAID ANY ADDITIONAL MONEY TO ANY MEMBER/AGENT OR EMPLOYEE", :sequence_number => 8, :created_at => Date.today)
    @checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "CONFIRM THAT ALL CLAIMS HAVE BEEN SETTLED AND NO AMOUNT IS PENDING", :sequence_number => 9, :created_at => Date.today)
    @checkpoint10=Checkpoint.create!(:section_id => @section1.id, :name => "CONFIRM THAT THE CENTER MEETING PLACE OR TIME NOT CHANGED", :sequence_number => 10, :created_at => Date.today)
    @checkpoint11=Checkpoint.create!(:section_id => @section1.id, :name => "CONFIRM THAT CENTER FILE HAS BEEN UPDATED WITH PREVIOUS SURPRISE VISITS", :sequence_number => 11, :created_at => Date.today)
    @checkpoint12=Checkpoint.create!(:section_id => @section1.id, :name => "ARE THERE ANY CONCERNS ABOUT THIS CENTER", :sequence_number => 12, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "GENERAL COMMENTS:", :sequence_number => 13, :created_at => Date.today)
    @free_text8=FreeText.create!(:section_id => @section1.id, :name => "Customer Comments", :sequence_number => 14, :created_at => Date.today)
    @free_text8=FreeText.create!(:section_id => @section1.id, :name => "Name of The officer", :sequence_number => 15, :created_at => Date.today)
    #@dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "Name Of Officer", :model_name => "StaffMember", :sequence_number => 15, :created_at => Date.today)
    @free_text3=FreeText.create!(:section_id => @section1.id, :name => "Date", :sequence_number => 16, :created_at => Date.today)
    @free_text4=FreeText.create!(:section_id => @section1.id, :name => "Place", :sequence_number => 17, :created_at => Date.today)
  end

#---------------------------------------------------------------Data for SCV generated---------------------------------------------------------------#


#---------------------------------------------------------------Generate data for BA---------------------------------------------------------------#

  def self.generate_business_audit_data
    #generate data for business audit


    @checklist_type= ChecklistType.create!(:name => "Business Audit", :created_at => Date.today)

    @checklist=Checklist.create!(:name => "Business Audit", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    #data for business_audit->deviations

    @section_type1=SectionType.create!(:name => "Deviations", :created_at => Date.today)
    @section1=Section.create!(:section_type_id => @section_type1.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Deviations", :created_at => Date.today)
    @dropdownpoint2=Dropdownpoint.create!(:section_id => @section1.id, :name => "Approved By", :model_name => "StaffMember", :sequence_number => 1, :created_at => Date.today)
    @free_text6=FreeText.create!(:section_id => @section1.id, :name => "Member Name", :sequence_number => 2, :created_at => Date.today)
    @dropdownpoint3=Dropdownpoint.create!(:section_id => @section1.id, :name => "Type of deviation", :model_name => "DeviationType", :sequence_number => 3, :created_at => Date.today)
    @dropdownpoint3=Dropdownpoint.create!(:section_id => @section1.id, :name => "Reason For Rejection", :model_name => "RejectionReason", :sequence_number => 4, :created_at => Date.today)
    @free_text6=FreeText.create!(:section_id => @section1.id, :name => "Details", :sequence_number => 5, :created_at => Date.today)
    @free_text6=FreeText.create!(:section_id => @section1.id, :name => "Date", :sequence_number => 6, :created_at => Date.today)
    @free_text6=FreeText.create!(:section_id => @section1.id, :name => "Action Taken", :sequence_number => 7, :created_at => Date.today)


    #@checklist=Checklist.create!(:name => "CGT", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    #Data corresponding to section 1 in the sheet

    @section_type1=SectionType.create!(:name => "CGT-Day1", :created_at => Date.today)
    @section1=Section.create!(:section_type_id => @section_type1.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "CGT-Day1", :created_at => Date.today)
    @checkpoint1=Checkpoint.create!(:section_id => @section1.id, :name => "Self-introduction by relationship officer", :sequence_number => 1, :created_at => Date.today)
    @checkpoint2=Checkpoint.create!(:section_id => @section1.id, :name => "Introduction of suryoday-vission/mission", :sequence_number => 2, :created_at => Date.today)
    @checkpoint3=Checkpoint.create!(:section_id => @section1.id, :name => "Current scenario of the microfinance industry", :sequence_number => 3, :created_at => Date.today)
    @checkpoint4=Checkpoint.create!(:section_id => @section1.id, :name => "Pledge and center announcement", :sequence_number => 4, :created_at => Date.today)
    @checkpoint5=Checkpoint.create!(:section_id => @section1.id, :name => " Seating arrangement", :sequence_number => 5, :created_at => Date.today)
    @checkpoint6=Checkpoint.create!(:section_id => @section1.id, :name => "Eligibility criteria to become member", :sequence_number => 6, :created_at => Date.today)
    @checkpoint7=Checkpoint.create!(:section_id => @section1.id, :name => "Joint liability group model", :sequence_number => 7, :created_at => Date.today)
    @checkpoint8=Checkpoint.create!(:section_id => @section1.id, :name => "Transparency", :sequence_number => 8, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Comments", :sequence_number => 9, :created_at => Date.today)

    #Data corresponding to section 2 in the sheet

    @section_type2=SectionType.create!(:name => "CGT-Day2")
    @section2=Section.create!(:section_type_id => @section_type2.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "CGT-Day2", :created_at => Date.today)
    @checkpoint1=Checkpoint.create!(:section_id => @section2.id, :name => "Revision of Day1", :sequence_number => 1, :created_at => Date.today)
    @checkpoint2=Checkpoint.create!(:section_id => @section2.id, :name => "Income eligibility criteria", :sequence_number => 2, :created_at => Date.today)
    @checkpoint3=Checkpoint.create!(:section_id => @section2.id, :name => " Details of loan product", :sequence_number => 3, :created_at => Date.today)
    @checkpoint4=Checkpoint.create!(:section_id => @section2.id, :name => "Details of fees and charges", :sequence_number => 4, :created_at => Date.today)
    @checkpoint5=Checkpoint.create!(:section_id => @section2.id, :name => " Details of rate of interest", :sequence_number => 5, :created_at => Date.today)
    @checkpoint6=Checkpoint.create!(:section_id => @section2.id, :name => " Loan amount and installment details", :sequence_number => 6, :created_at => Date.today)
    @checkpoint7=Checkpoint.create!(:section_id => @section2.id, :name => " Insurance and claim process", :sequence_number => 7, :created_at => Date.today)
    @checkpoint8=Checkpoint.create!(:section_id => @section2.id, :name => "Process of center meeting", :sequence_number => 8, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section2.id, :name => "Comments", :sequence_number => 9, :created_at => Date.today)


    #Data corresponding to section 3 in the sheet

    @section_type3=SectionType.create!(:name => "CGT-Day3")
    @section3=Section.create!(:section_type_id => @section_type3.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "CGT-Day3", :created_at => Date.today)
    @checkpoint1=Checkpoint.create!(:section_id => @section3.id, :name => "Revision of Day 1 and 2", :sequence_number => 1, :created_at => Date.today)
    @checkpoint2=Checkpoint.create!(:section_id => @section3.id, :name => "Multiple borrowing", :sequence_number => 2, :created_at => Date.today)
    @checkpoint3=Checkpoint.create!(:section_id => @section3.id, :name => " Pre-closure of loan", :sequence_number => 3, :created_at => Date.today)
    @checkpoint4=Checkpoint.create!(:section_id => @section3.id, :name => " Process of pre-closure", :sequence_number => 4, :created_at => Date.today)
    @checkpoint5=Checkpoint.create!(:section_id => @section3.id, :name => " Audit visit", :sequence_number => 5, :created_at => Date.today)
    @checkpoint6=Checkpoint.create!(:section_id => @section3.id, :name => " Saving habit", :sequence_number => 6, :created_at => Date.today)
    @checkpoint7=Checkpoint.create!(:section_id => @section3.id, :name => " Question and Answer", :sequence_number => 7, :created_at => Date.today)
    @checkpoint8=Checkpoint.create!(:section_id => @section3.id, :name => " End of training and GRT announcement", :sequence_number => 8, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section3.id, :name => "Comments", :sequence_number => 9, :created_at => Date.today)

    #checklist for center  meeting
    #@checklist=Checklist.create!(:name => "Center Meeting", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    @section_type1=SectionType.create!(:name => "Center Meeting", :created_at => Date.today)
    @section1=Section.create!(:section_type_id => @section_type1.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Center Meeting", :created_at => Date.today)
    #@dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "Center Name", :model_name => "Center", :sequence_number => 1, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Center meeting date and time", :sequence_number => 1, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "which EWI/EMI", :sequence_number => 2, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Center Leader name", :sequence_number => 3, :created_at => Date.today)
    #@dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "Center Leader Name", :model_name => "StaffMember", :sequence_number => 3, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Members present", :sequence_number => 4, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Attendance in percentage", :sequence_number => 5, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Current Attendance", :sequence_number => 6, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Previous Attedance", :sequence_number => 7, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Next Attendance", :sequence_number => 8, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Observations", :sequence_number => 9, :created_at => Date.today)

    #checklist for CGT GRT visit:

    #@checklist=Checklist.create!(:name => "CGT/GRT visit", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    #data for business_audit->deviations
    @section_type1=SectionType.create!(:name => "CGT-GRT visit", :created_at => Date.today)
    @section1=Section.create!(:section_type_id => @section_type1.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "CGT-GRT visits", :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Center meeting date and time", :sequence_number => 1, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Center Leader Name", :sequence_number => 2, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Center RO Name", :sequence_number => 3, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Observations", :sequence_number => 4, :created_at => Date.today)


    #checklist for GRT
    #@checklist=Checklist.create!(:name => "GRT(questions)", :checklist_type_id => @checklist_type.id, :created_at => Date.today)

    @section_type3=SectionType.create!(:name => "GRT(questions)", :created_at => Date.today)
    @section3=Section.create!(:section_type_id => @section_type3.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "GRT(questions)", :created_at => Date.today)

    @checkpoint1=Checkpoint.create!(:section_id => @section3.id, :name => "Name of the relationship officer", :sequence_number => 1, :created_at => Date.today)
    @checkpoint1=Checkpoint.create!(:section_id => @section3.id, :name => "Name and location of our organisation", :sequence_number => 2, :created_at => Date.today)
    @checkpoint1=Checkpoint.create!(:section_id => @section3.id, :name => "Client eligible criteria", :sequence_number => 3, :created_at => Date.today)
    @checkpoint1=Checkpoint.create!(:section_id => @section3.id, :name => "Loan amount group member applied for", :sequence_number => 4, :created_at => Date.today)
    @checkpoint1=Checkpoint.create!(:section_id => @section3.id, :name => "Our product", :sequence_number => 5, :created_at => Date.today)
    @checkpoint2=Checkpoint.create!(:section_id => @section3.id, :name => "Interest rate and amount", :sequence_number => 6, :created_at => Date.today)
    @checkpoint3=Checkpoint.create!(:section_id => @section3.id, :name => " Insurance benefits", :sequence_number => 7, :created_at => Date.today)
    @checkpoint4=Checkpoint.create!(:section_id => @section3.id, :name => " Monthly installment payable", :sequence_number => 8, :created_at => Date.today)
    @checkpoint5=Checkpoint.create!(:section_id => @section3.id, :name => "  No. of monthly installments", :sequence_number => 9, :created_at => Date.today)
    @checkpoint6=Checkpoint.create!(:section_id => @section3.id, :name => "Role and responsibility as a JLG member", :sequence_number => 10, :created_at => Date.today)
    @checkpoint7=Checkpoint.create!(:section_id => @section3.id, :name => "Center no. and location", :sequence_number => 11, :created_at => Date.today)
    @checkpoint8=Checkpoint.create!(:section_id => @section3.id, :name => "  Center meeting date and time", :sequence_number => 12, :created_at => Date.today)
    @checkpoint9=Checkpoint.create!(:section_id => @section3.id, :name => "Group leader and center leader's role and responsibility", :sequence_number => 13, :created_at => Date.today)
    @checkpoint9=Checkpoint.create!(:section_id => @section3.id, :name => "Other members name, address and income source", :sequence_number => 14, :created_at => Date.today)
    @checkpoint9=Checkpoint.create!(:section_id => @section3.id, :name => "Timely and regular payment benefits", :sequence_number => 15, :created_at => Date.today)
    @checkpoint9=Checkpoint.create!(:section_id => @section3.id, :name => "Member sense of belonginess to JLG", :sequence_number => 16, :created_at => Date.today)
    @checkpoint9=Checkpoint.create!(:section_id => @section3.id, :name => "Willingness about timely repayments", :sequence_number => 17, :created_at => Date.today)
    @checkpoint9=Checkpoint.create!(:section_id => @section3.id, :name => "Consistency at the time of GRT", :sequence_number => 18, :created_at => Date.today)
    @checkpoint9=Checkpoint.create!(:section_id => @section3.id, :name => "Knowledge and skill of the activity for which loan has been applied", :sequence_number => 19, :created_at => Date.today)


    #branch visit details
    #@checklist=Checklist.create!(:name => "Branch visit Details", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    @section_type4=SectionType.create!(:name => "Branch visit details", :created_at => Date.today)
    @section1=Section.create!(:section_type_id => @section_type4.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Branch visit details", :created_at => Date.today,:has_score=>true)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Name of the visitor", :sequence_number => 1, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Designation", :sequence_number => 2, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Date and time he reached office", :sequence_number => 3, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section1.id, :name => "Time he left office", :sequence_number => 4, :created_at => Date.today)

    #Cash book/pity cash book maintenance

    #@checklist=Checklist.create!(:name => "Cash book/pity cash book maintenance", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    #@section_type4=SectionType.create!(:name => "Cash book/petty cash book maintenance", :created_at => Date.today)
    #@section1=Section.create!(:section_type_id => @section_type4.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Cash book/petty cash book maintenance", :created_at => Date.today)
    @dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "Cash book/petty cash book maintenance", :model_name => "CashBookValue", :sequence_number => 5, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Cash book/petty cash book maintenance is very good with all enteries posted and proper authentication obtained", :sequence_number => 1, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Cash book/petty cash book maintenance is Ok but needs few corrections and improvements", :sequence_number => 2, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Cash book/petty cash book maintenance is Not Ok and needs lot of correction and improvement", :sequence_number => 3, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Stock registers maintenance for Receipt book", :sequence_number => 4, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Register maintained and updated regularly", :sequence_number => 5, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Register maintained and not updated regularly", :sequence_number => 6, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Register not maintained", :sequence_number => 7, :created_at => Date.today)


    #stock register maintanence
    #@section_type4=SectionType.create!(:name => "Stock Register maintenance", :created_at => Date.today)
    #@section1=Section.create!(:section_type_id => @section_type4.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Stock Register maintenance", :created_at => Date.today)
    @dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => " Stock Register maintenance", :model_name => "StockRegisterValue", :sequence_number => 6, :created_at => Date.today)

    #Register maintenance

    #@checklist=Checklist.create!(:name => "Register maintenance", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    #@section_type4=SectionType.create!(:name => "Register maintenance", :created_at => Date.today)
    #@section1=Section.create!(:section_type_id => @section_type4.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Register maintenance", :created_at => Date.today)
    @dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "Register maintenance", :model_name => "RegisterMaintanenceValue", :sequence_number => 7, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Register maintained and daily entries are regularly updated in the register", :sequence_number => 1, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Register maintained but entries are not regularly updated on a daily basis. Few enteries are made in the register at some long intervals ", :sequence_number => 2, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Register is maintained but no entries are made in it", :sequence_number => 3, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Register is not maintained at all", :sequence_number => 4, :created_at => Date.today)


    #comments On cleanliness

    #@checklist=Checklist.create!(:name => "comments On cleanliness", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    #@section_type4=SectionType.create!(:name => "Comments on cleanliness", :created_at => Date.today)
    #@section1=Section.create!(:section_type_id => @section_type4.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Comments on cleanliness ", :created_at => Date.today)
    @dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "Comments on cleanliness ", :model_name => "CleanlinessCommentValue", :sequence_number => 8, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Unnecessary items not seen at all in the branch", :sequence_number => 1, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Unnecessary items partially seen in the branch", :sequence_number => 2, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Unnecessary items seen all over the branch", :sequence_number => 3, :created_at => Date.today)

    #Cash and collection report

    #@checklist=Checklist.create!(:name => "Cash and collection report", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    #@section_type4=SectionType.create!(:name => "Cash and collection report", :created_at => Date.today)
    #@section1=Section.create!(:section_type_id => @section_type4.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Cash and collection report", :created_at => Date.today)
    @dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "Cash and Collection Reports ", :model_name => "CashAndCollectionReport", :sequence_number => 9, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Are RO's are coming back iin time after last meeting", :sequence_number => 1, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Cash collected and deposited in bank in time", :sequence_number => 2, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Pending cash kept in safe and reported properly", :sequence_number => 3, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Cash report send by AO", :sequence_number => 4, :created_at => Date.today)


    #Due sheets file

    # @checklist=Checklist.create!(:name => "Due sheets file", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    # @section_type4=SectionType.create!(:name => "Due sheets file")
    # @section1=Section.create!(:section_type_id => @section_type4.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Due sheets file", :created_at => Date.today)
    @dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "Due Sheet File Value", :model_name => "DueSheetFileValue", :sequence_number => 10, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "5 box files maintained and reports filed regularly", :sequence_number => 1, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "5 box files maintained and reports NOT filed regularly", :sequence_number => 2, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Box files not maintained", :sequence_number => 3, :created_at => Date.today)


    #Camera and photos

    #@checklist=Checklist.create!(:name => "Camera and photos", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    #@section_type4=SectionType.create!(:name => "Camera and photos", :created_at => Date.today)
    #@section1=Section.create!(:section_type_id => @section_type4.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Camera and photos", :created_at => Date.today)
    @dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "Camera and photos  ", :model_name => "PhotoValue", :sequence_number => 11, :created_at => Date.today)

    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "2 photos taken and updated to picasa site", :sequence_number => 1, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "2 photos taken and not updated to picasa site", :sequence_number => 2, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Photos not taken", :sequence_number => 3, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Photos not taken", :sequence_number => 4, :created_at => Date.today)


    #Display of charts/boards/infrastructure in the branch

    # @checklist=Checklist.create!(:name => "Display of charts/boards/infrastructure", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    # @section_type4=SectionType.create!(:name => "Display of charts/boards/infrastructure in the branch", :created_at => Date.today)
    # @section1=Section.create!(:section_type_id => @section_type4.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Display of charts/boards/infrastructure in the branch", :created_at => Date.today)
    @dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "Display of charts/boards/infrastructure in the branch", :model_name => "InfrastructureValue", :sequence_number => 12, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "RBI registration certificate/Shop Act/Company registration", :sequence_number => 1, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Area survey chart/ branch approval", :sequence_number => 2, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "RO capacity chart", :sequence_number => 3, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Branch information in White Board as per format", :sequence_number => 4, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Copy of process note and training kit", :sequence_number => 5, :created_at => Date.today)
    #@checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => "Working of PC and Net", :sequence_number => 6, :created_at => Date.today)


  end

#---------------------------------------------------------------Data for BA generated---------------------------------------------------------------#


#----------------------------------------------------Generate Data for Healthcheck on loans----------------------------------------------------------#
  def self.generate_hc_data

    #health check on loan files

    @checklist_type= ChecklistType.create!(:name => "HealthCheck on Loan Files", :created_at => Date.today)
    @checklist=Checklist.create!(:name => "HealthCheck", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    #Data corresponding to section 1 in the sheet

    #section 1
    @section_type1=SectionType.create!(:name => "Section 1", :created_at => Date.today)
    @section1=Section.create!(:section_type_id => @section_type1.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Section1", :created_at => Date.today)
    @checkpoint5=Checkpoint.create!(:section_id => @section1.id, :name => " Credit Approval", :sequence_number => 1, :created_at => Date.today)
    @checkpoint2=Checkpoint.create!(:section_id => @section1.id, :name => " CGT Sheet", :sequence_number => 2, :created_at => Date.today)
    @checkpoint3=Checkpoint.create!(:section_id => @section1.id, :name => "Center undertaking", :sequence_number => 3, :created_at => Date.today)
    @checkpoint4=Checkpoint.create!(:section_id => @section1.id, :name => " GRT sheet", :sequence_number => 4, :created_at => Date.today)
    @checkpoint5=Checkpoint.create!(:section_id => @section1.id, :name => " Map", :sequence_number => 5, :created_at => Date.today)
    @free_text3=FreeText.create!(:section_id => @section1.id, :name => "Distance", :sequence_number => 6, :created_at => Date.today)
    @checkpoint6=Checkpoint.create!(:section_id => @section1.id, :name => "MFtrack", :sequence_number => 7, :created_at => Date.today)
    @checkpoint7=Checkpoint.create!(:section_id => @section1.id, :name => "Rented", :sequence_number => 8, :created_at => Date.today)
    @checkpoint8=Checkpoint.create!(:section_id => @section1.id, :name => "Single Women", :sequence_number => 9, :created_at => Date.today)


    #section 2(repeated 15 times)
    @section_type2=SectionType.create!(:name => "Section 2", :created_at => Date.today)

    @section2=Section.create!(:section_type_id => @section_type2.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Section2", :created_at => Date.today)
    #repeacted 15 times
    #final_sequence=0
    #15.times do |i|
    #
    #  @checkboxpoint1=Checkboxpoint.create!(:section_id => @section2.id, :name => "GS#{(((i+5)%5)+1)}-#{(i%5)+1}", :sequence_number => (final_sequence+1), :created_at => Date.today)
    #  @checkboxpoint_option1=CheckboxpointOption.create!(:checkboxpoint_id => @checkboxpoint1.id, :name => "Address proof", :sequence_number => 1, :created_at => Date.today)
    #  @checkboxpoint_option1=CheckboxpointOption.create!(:checkboxpoint_id => @checkboxpoint1.id, :name => "ID proof", :sequence_number => 2, :created_at => Date.today)
    #  @checkboxpoint_option1=CheckboxpointOption.create!(:checkboxpoint_id => @checkboxpoint1.id, :name => "Age", :sequence_number => 3, :created_at => Date.today)
    #  @checkboxpoint_option1=CheckboxpointOption.create!(:checkboxpoint_id => @checkboxpoint1.id, :name => "Ration Card", :sequence_number => 4, :created_at => Date.today)
    #  @checkboxpoint_option1=CheckboxpointOption.create!(:checkboxpoint_id => @checkboxpoint1.id, :name => "Extra Photo", :sequence_number => 5, :created_at => Date.today)
    #  @checkboxpoint_option1=CheckboxpointOption.create!(:checkboxpoint_id => @checkboxpoint1.id, :name => "Member/Guarantor sign ", :sequence_number => 6, :created_at => Date.today)
    #  @checkboxpoint_option1=CheckboxpointOption.create!(:checkboxpoint_id => @checkboxpoint1.id, :name => "BM/RO/AO sign ", :sequence_number => 7, :created_at => Date.today)
    #  @checkboxpoint_option1=CheckboxpointOption.create!(:checkboxpoint_id => @checkboxpoint1.id, :name => "Term Sheet", :sequence_number => 8, :created_at => Date.today)
    #  @checkboxpoint_option1=CheckboxpointOption.create!(:checkboxpoint_id => @checkboxpoint1.id, :name => "DPN", :sequence_number => 9, :created_at => Date.today)
    #  @checkboxpoint_option1=CheckboxpointOption.create!(:checkboxpoint_id => @checkboxpoint1.id, :name => "DeDupe", :sequence_number => 10, :created_at => Date.today)
    #  @free_text4=FreeText.create!(:section_id => @section2.id, :name => "Remark", :sequence_number => (final_sequence+2), :created_at => Date.today)
    #  final_sequence=final_sequence+2
    #
    #end


    #section 3
    @section_type3=SectionType.create!(:name => "Section 3", :created_at => Date.today)
    @section3=Section.create!(:section_type_id => @section_type3.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Section3", :created_at => Date.today)
    @dropdownpoint2=Dropdownpoint.create!(:section_id => @section3.id, :name => " Checked By", :model_name => "StaffMember", :sequence_number => 1, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section3.id, :name => "Date", :sequence_number => 2, :created_at => Date.today)
    @free_text1=FreeText.create!(:section_id => @section3.id, :name => "Query Solving Date", :sequence_number => 3, :created_at => Date.today)
    @dropdownpoint2=Dropdownpoint.create!(:section_id => @section3.id, :name => " Name", :model_name => "StaffMember", :sequence_number => 4, :created_at => Date.today)


  end

#---------------------------------------------------------------Data for HC generated---------------------------------------------------------------#


#------------------------------------------------------Generate Data for Process Audit---------------------------------------------------------------#


  def self.generate_process_audit_data
#process Audit


    @checklist_type= ChecklistType.create!(:name => "Process Audit", :created_at => Date.today)
    @checklist=Checklist.create!(:name => "Process Audit", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    #Data corresponding to section 1 in the sheet
    @section_type1=SectionType.create!(:name => "Deviations", :created_at => Date.today)

    @section1=Section.create!(:section_type_id => @section_type1.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Deviations", :created_at => Date.today)

    @dropdownpoint3=Dropdownpoint.create!(:section_id => @section1.id, :name => "Type of deviation", :model_name => "DeviationType", :sequence_number => 1, :created_at => Date.today)
    @dropdownpoint5=Dropdownpoint.create!(:section_id => @section1.id, :name => "Action taken by", :model_name => "StaffMember", :sequence_number => 2, :created_at => Date.today)
    @free_text6=FreeText.create!(:section_id => @section1.id, :name => "Deviation", :sequence_number => 3, :created_at => Date.today)

  end

#---------------------------------------------------- Data for Process Audit Generated---------------------------------------------------------------#

#---------------------------------------------------Generate Data for Customer Calling---------------------------------------------------------------#
  def self.generate_customer_calling_data

    #customer calling


    @checklist_type= ChecklistType.create!(:name => "Customer Calling", :created_at => Date.today)
    @checklist=Checklist.create!(:name => "Tele-Calling format", :checklist_type_id => @checklist_type.id, :created_at => Date.today)
    #Data corresponding to section 1 in the sheet


    @section_type1=SectionType.create!(:name => "Section 1", :created_at => Date.today)

    @section1=Section.create!(:section_type_id => @section_type1.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Tele Calling Format", :created_at => Date.today)
    #@checkpoint1=Checkpoint.create!(:section_id => @section1.id, :name => "Location", :sequence_number => 1, :created_at => Date.today)
    #@free_text1=FreeText.create!(:section_id => @section1.id, :name => "Comments", :sequence_number => 2, :created_at => Date.today)
    #
    #@checkpoint2=Checkpoint.create!(:section_id => @section1.id, :name => "Branch", :sequence_number => 3, :created_at => Date.today)
    #@free_text2=FreeText.create!(:section_id => @section1.id, :name => "Comments", :sequence_number => 4, :created_at => Date.today)
    #
    #
    #@checkpoint3=Checkpoint.create!(:section_id => @section1.id, :name => "Center", :sequence_number => 5, :created_at => Date.today)
    #@free_text3=FreeText.create!(:section_id => @section1.id, :name => "Comments", :sequence_number => 6, :created_at => Date.today)
    #
    #@checkpoint4=Checkpoint.create!(:section_id => @section1.id, :name => "Customer name", :sequence_number => 7, :created_at => Date.today)
    #@checkpoint5=Checkpoint.create!(:section_id => @section1.id, :name => "Contact number", :sequence_number => 8, :created_at => Date.today)
    @checkpoint1=Checkpoint.create!(:section_id => @section1.id, :name => "RO name", :sequence_number => 1, :created_at => Date.today)
    @checkpoint2=Checkpoint.create!(:section_id => @section1.id, :name => "Contact Number", :sequence_number => 2, :created_at => Date.today)
    @dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "RO CPV", :model_name => "ValueForCpvDropDown", :sequence_number => 3, :created_at => Date.today)
    @dropdownpoint2=Dropdownpoint.create!(:section_id => @section1.id, :name => "AO CPV", :model_name => "ValueForCpvDropDown", :sequence_number => 4, :created_at => Date.today)
    @free_text6=FreeText.create!(:section_id => @section1.id, :name => "Comments", :sequence_number => 5, :created_at => Date.today)
    @free_text6=FreeText.create!(:section_id => @section1.id, :name => "CGT meeting place", :sequence_number => 6, :created_at => Date.today)
    @free_text6=FreeText.create!(:section_id => @section1.id, :name => "GRT meeting place", :sequence_number => 7, :created_at => Date.today)


    @checkpoint8=Checkpoint.create!(:section_id => @section1.id, :name => "  Disbursement issues", :sequence_number => 8, :created_at => Date.today)


    @checkpoint9=Checkpoint.create!(:section_id => @section1.id, :name => " Disbursement TAT", :sequence_number => 9, :created_at => Date.today)


    @checkpoint10=Checkpoint.create!(:section_id => @section1.id, :name => " Salaried Members", :sequence_number => 10, :created_at => Date.today)
    @free_text10=FreeText.create!(:section_id => @section1.id, :name => "Comments", :sequence_number => 11, :created_at => Date.today)


    @checkpoint10=Checkpoint.create!(:section_id => @section1.id, :name => "Extra payment", :sequence_number => 12, :created_at => Date.today)


    @free_text2=FreeText.create!(:section_id => @section1.id, :name => "Extra pay amount", :sequence_number => 13, :created_at => Date.today)
    @free_text2=FreeText.create!(:section_id => @section1.id, :name => "Extra payment made to", :sequence_number => 14, :created_at => Date.today)

    @dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "Loan Utilization", :model_name => "LoanUtilizationValue", :sequence_number => 15, :created_at => Date.today)
    @dropdownpoint1=Dropdownpoint.create!(:section_id => @section1.id, :name => "Experience with SMF", :model_name => "ExperienceValue", :sequence_number => 16, :created_at => Date.today)


    @checkpoint11=Checkpoint.create!(:section_id => @section1.id, :name => "Wrong number", :sequence_number => 17, :created_at => Date.today)
    @free_text3=FreeText.create!(:section_id => @section1.id, :name => "Remarks", :sequence_number => 18, :created_at => Date.today)
    @free_text3=FreeText.create!(:section_id => @section1.id, :name => "Second call date", :sequence_number => 19, :created_at => Date.today)


    @free_text3=FreeText.create!(:section_id => @section1.id, :name => "Date", :sequence_number => 20, :created_at => Date.today)
    @free_text3=FreeText.create!(:section_id => @section1.id, :name => "Time", :sequence_number => 21, :created_at => Date.today)


    @section_type2=SectionType.create!(:name => "Questionnaire", :created_at => Date.today)
    @section2=Section.create!(:section_type_id => @section_type1.id, :instructions => "Please Fill in the answers Below:", :checklist_id => @checklist.id, :name => "Questionnaire", :created_at => Date.today)


    @free_text1=FreeText.create!(:section_id => @section2.id, :name => "How was your experience in obtaining a loan from SMF?", :sequence_number => 1, :created_at => Date.today)
    @free_text2=FreeText.create!(:section_id => @section2.id, :name => "Did you all face any problem in getting the loan from SMF? In how many days did you get the loan?", :sequence_number => 2, :created_at => Date.today)
    @free_text3=FreeText.create!(:section_id => @section2.id, :name => "Is there any body in your group who is not doing any business and is employed in a job for a monthly salary ?", :sequence_number => 3, :created_at => Date.today)
    @free_text4=FreeText.create!(:section_id => @section2.id, :name => "How many of your houses did the RO visit for varification ?", :sequence_number => 4, :created_at => Date.today)
    @free_text5=FreeText.create!(:section_id => @section2.id, :name => "Did you make any extra payment apart from the initial payment to anybody else ? If so how much payment was made and to whom the payment was made?", :sequence_number => 5, :created_at => Date.today)
    @free_text6=FreeText.create!(:section_id => @section2.id, :name => "Did all the members in your group use the entire loan fully for their business or profession ? Or partly for their business or profession ?", :sequence_number => 6, :created_at => Date.today)

  end

#---------------------------------------------------Data for Customer Calling Generated--------------------------------------------------------------#


#this is master method which calls all other methods...
  def self.generate_sample_data

    ChecklistType.destroy_existing_data
    ChecklistType.generate_scv_data
    ChecklistType.generate_business_audit_data
    ChecklistType.generate_hc_data
    ChecklistType.generate_process_audit_data
    ChecklistType.generate_customer_calling_data

    ChecklistType.delete_other_seed_data
    ChecklistType.generate_seed_data


  end


  def self.delete_other_seed_data
    ExperienceValue.all.destroy
    LoanUtilizationValue.all.destroy
    DeviationType.all.destroy
    ValueForCpvDropDown.all.destroy
    RejectionReason.all.destroy

    CashAndCollectionReport.all.destroy
    CashBookValue.all.destroy
    CleanlinessCommentValue.all.destroy
    DueSheetFileValue.all.destroy
    InfrastructureValue.all.destroy
    PhotoValue.all.destroy
    RegisterMaintanenceValue.all.destroy
    StockRegisterValue.all.destroy


  end

  def self.generate_seed_data
    ExperienceValue.generate_seed_data
    LoanUtilizationValue.generate_seed_data
    DeviationType.generate_seed_data
    ValueForCpvDropDown.generate_seed_data
    RejectionReason.generate_seed_data

    CashAndCollectionReport.generate_seed_data
    CashBookValue.generate_seed_data
    CleanlinessCommentValue.generate_seed_data
    DueSheetFileValue.generate_seed_data
    InfrastructureValue.generate_seed_data
    PhotoValue.generate_seed_data
    RegisterMaintanenceValue.generate_seed_data
    StockRegisterValue.generate_seed_data

  end


  #####these are methods to get different type of checklists#####

  def self.get_scv_checklist
    ChecklistType.all(:name => "Surprise Center Visit").first
  end

  def self.get_ba_checklist
    ChecklistType.all(:name => "Business Audit").first

  end

  def self.get_pa_checklist
    ChecklistType.all(:name => "Process Audit").first
  end

  def self.get_hc_checklist
    ChecklistType.all(:name => "HealthCheck on Loan Files").first

  end

  def self.get_cc_checklist
    ChecklistType.all(:name => "Customer Calling").first
  end



  #################these are instance methods which return true or false####################################
  def is_hc_checklist?
    if self.name=="HealthCheck on Loan Files"
      true
    else
      false
    end
  end

  def is_scv_checklist?
    if self.name=="Surprise Center Visit"
      true
    else
      false
    end
  end

  def is_ba_checklist?
    if self.name=="Business Audit"
      true
    else
      false
    end
  end

  def is_cc_checklist?
    if self.name=="Customer Calling"
      true
    else
      false
    end
  end

  def is_pa_checklist?
    if self.name=="Process Audit"
      true
    else
      false
    end
  end




end

