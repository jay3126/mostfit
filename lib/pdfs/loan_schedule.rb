require 'pdf/quickref'
module Pdf
  module LoanSchedule

    def generate_loan_schedule
      loan_history = self.loan_history
      return nil if loan_history.empty?
      pdf =  PDF::Writer.new(:orientation => :portrait, :paper => "A4")
      pdf.select_font "Times-Roman"
      pdf.text "Repayment Schedule of Loan ID #{self.id} for client #{self.client.name} (ID: #{self.client.id})", :font_size => 18, :justification => :center
      pdf.text("\n")
      client_info = PDF::SimpleTable.new
      client_info.data = []
      client_info.data.push({ "identifier" => "Amount Applied", "value" => "#{self.amount_applied_for.to_currency } by #{self.applied_by.name} on #{self.applied_on.strftime("%d-%m-%Y")}"})
      if not self.approved_on.nil?
        client_info.data.push({ "identifier" => "Amount Sanctioned", "value" => "#{self.amount_sanctioned.to_currency} by #{self.approved_by.name} on #{self.approved_on.strftime("%d-%m-%Y")}"}) 
      end
      if not self.disbursal_date.nil?
        client_info.data.push({ "identifier" => "Amount Disbursed", "value" => "#{self.amount.to_currency} by #{self.disbursed_by.name} on #{self.disbursal_date.strftime("%d-%m-%Y")}"}) 
      end
      client_info.data.push({ "identifier" => "Loan Product", "value" => self.loan_product.name },
        { "identifier" => "Loan Type", "value" => self.type.to_s }
      )
      self.applicable_fees.each_with_index do |fee, idx|
        client_info.data.push({ "identifier" => "Fee #{idx + 1}", "value" => "#{Fee.get(fee.fee_id).name} of amount #{fee.amount} applicable on #{fee.applicable_on.strftime("%d-%m-%Y")}"})
      end
      client_info.column_order  = ["identifier", "value"]
      client_info.show_lines    = :none
      client_info.show_headings = false
      client_info.shade_rows    = :none
      client_info.shade_headings = false
      client_info.orientation   = :center
      client_info.position      = :center
      client_info.title_font_size = 13
      client_info.header_gap = 10
      client_info.render_on(pdf)
      pdf.text("\n")
      table = PDF::SimpleTable.new
      table.data = []
      loan_history.each_with_index do |lh, i|
        scheduled_principal = i > 0 ? (loan_history[i-1].scheduled_outstanding_principal - lh.scheduled_outstanding_principal) : 0
        scheduled_interest =  i > 0 ? (loan_history[i-1].scheduled_outstanding_total - lh.scheduled_outstanding_total - scheduled_principal) : 0
        table.data.push({"Date Due" => lh.date, "Scheduled Balance" => lh.scheduled_outstanding_principal.to_currency, 
            "Scheduled Principal" => scheduled_principal.to_currency,
            "Scheduled Interest" => scheduled_interest.to_currency,
            "Scheduled Total" => (scheduled_principal + scheduled_interest).to_currency,
            "RO Signature" => "",
          })
        # if 
        # table.data.push({ "actual balance" => "",
        #                   "actual repayments"  => ""
        #                 })
        # end
      end
      table.column_order  = ["Date Due", "Scheduled Balance", "Scheduled Principal", "Scheduled Interest", "Scheduled Total", "RO Signature"]
      table.show_lines    = :all
      table.show_headings = true
      table.shade_rows    = :none
      table.shade_headings = true
      table.orientation   = :center
      table.position      = :center
      table.title_font_size = 14
      table.header_gap = 10
      table.render_on(pdf)
      return pdf
    end

    def generate_disbursement_labels_pdf(user_id, on_date)
      location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user_id)
      meeting_facade  = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, user_id)
      lendings        = location_facade.get_loans_administered(self.id, on_date).compact
      raise ArgumentError,"No loans for generate labels pdf" if lendings.blank?

      pdf            = PDF::QuickRef.new("LETTER", 2)
      pdf.body_font_size  = 8
      pdf.h1_font_size = 8
      count   = 0
      meeting = meeting_facade.get_meeting(self, on_date)
      lendings.each do |la|
        client        = la.borrower
        count         = count + 1
        start_date    = la.scheduled_first_repayment_date
        end_date      = la.last_scheduled_date
        disburse_date = la.scheduled_disbursal_date
        pdf.h1 "<b>Purpose of Loan</b>                   #{la.loan_purpose}"
        pdf.h1 "<b>Name</b>                                     #{client.nil? ? 'No Client' : client.name}"
        pdf.h1 "<b>Gtr. Name</b>                             #{client.nil? ? 'No Guarantor' : client.guarantor_name}"
        pdf.h1 "<b>Center Name</b>                         #{self.name}"
        pdf.h1 "<b>Meeting Address</b>                   #{}"
        if meeting.blank?
          pdf.h1 "<b>Meeting Day / Time</b>              No Meeting"
        else
          pdf.h1 "<b>Meeting Day / Time</b>              #{on_date}/#{meeting.meeting_time_begins_hours}:#{'%02d' % meeting.meeting_time_begins_minutes}"
        end
        pdf.h1 "<b>Disbursal Date</b>        #{disburse_date}        <b>Loan A/c. No.</b>       #{la.lan}"
        pdf.h1 "<b>Start Date</b>                #{start_date}        <b>End Date</b>               #{end_date}"
        pdf.body "\n"
        pdf.body "\n" if count%5 == 0
      end
      return pdf
    end

    def location_generate_disbursement_pdf(user_id, on_date)
      location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user_id)
      meeting_facade  = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, user_id)
      lendings        = location_facade.get_loans_administered(self.id, on_date).compact
      raise ArgumentError,"No loans for generate pdf" if lendings.blank?
      pdf = PDF::Writer.new(:orientation => :portrait, :paper => "A4")
      pdf.select_font "Times-Roman"
      return nil if lendings.blank?
      pdf.text "Suryoday Microfinance (P) Ltd.", :font_size => 18, :justification => :center
      pdf.text "Disbursal Report and Acknowledgement", :font_size => 16, :justification => :center
      pdf.text("\n")
      table1              = PDF::SimpleTable.new
      clients_count       = ClientAdministration.get_clients_administered(self.id, on_date).count
      location_manage     = location_facade.location_managed_by_staff(self.id, on_date)
      staff_member_name   = location_manage.blank? ? 'No Managed' : location_manage.manager_staff_member.name
      meeting             = meeting_facade.get_meeting(self, on_date)
      meeting_status      = meeting.blank? ? 'No Meeting' : "#{meeting.meeting_time_begins_hours}:#{'%02d' % meeting.meeting_time_begins_minutes}"
      table1.data = [{"col1"=>"<b>Location</b>", "col2"=>"#{self.name}", "col3"=>"<b>No. of Members</b>", "col4"=>"#{clients_count}"},
        {"col1"=>"<b>R.O Name</b>", "col2"=>"#{staff_member_name}", "col3"=>"<b>Scheduled Disbursal Date</b>", "col4"=>"#{on_date}"},
        {"col1"=>"<b>Meeting Address</b>", "col2"=>"#{}", "col3"=>"<b>Time</b>", "col4"=>"#{meeting_status}"}
      ]

      table1.column_order  = ["col1", "col2", "col3","col4"]
      table1.show_lines    = :none
      table1.shade_rows    = :none
      table1.show_headings = false
      table1.shade_headings = true
      table1.orientation   = :center
      table1.position      = :center
      table1.title_font_size = 16
      table1.header_gap = 20
      table1.width = 500
      table1.render_on(pdf)
      pdf.text("\n")

      #draw table for scheduled disbursals
      if lendings.count > 0
        table = PDF::SimpleTable.new
        table.data = []
        tot_amount = MoneyManager.get_money_instance(0)
        lendings.each do |loan|
          client        = loan.borrower
          client_name  = client.name unless client.blank?
          client_group = client.client_group.blank? ? 'Nothing' : client.client_group.name
          tot_amount = tot_amount + loan.to_money[:applied_amount] unless loan.to_money[:applied_amount].blank?
          table.data.push({"LAN"=> loan.id,"Disb. Amount" => loan.to_money[:applied_amount].to_s, "Name" => client_name,
              "Group" => client_group
            })
        end
        table.data.push({"Group"=>"Total=#{lendings.count}","Disb. Amount" => tot_amount.to_s})
        table.column_order  = ["LAN", "Name", "Group", "Disb. Amount"]
        table.show_lines    = :all
        table.shade_rows    = :none
        table.show_headings = true
        table.shade_headings = true
        table.orientation   = :center
        table.position      = :center
        table.title_font_size = 16
        table.header_gap = 20
        table.width = 500
        table.render_on(pdf)
        pdf.start_new_page if pdf.y < 315
        pdf.text("\n")
        pdf.rounded_rectangle(pdf.absolute_left_margin+10, pdf.y+pdf.top_margin - 30, 125, 50, 5).stroke
        pdf.rounded_rectangle(pdf.absolute_right_margin-215, pdf.y+pdf.top_margin - 30, 125, 50, 5).stroke
        pdf.rounded_rectangle(pdf.absolute_left_margin+10, pdf.y+pdf.top_margin - 115, 125, 50, 5).stroke
        pdf.rounded_rectangle(pdf.absolute_right_margin-215, pdf.y+pdf.top_margin - 115, 125, 50, 5).stroke
        pdf.rounded_rectangle(pdf.absolute_left_margin+10, pdf.y+pdf.top_margin - 210, 125, 50, 5).stroke
        pdf.text("\n")
        pdf.text("\n")
        pdf.text("\n")
        table2 = PDF::SimpleTable.new
        table2.data = [{"col1"=>"<b>Disbursement Authorised By</b>","col2"=>"<b>Disbursement Authorised By</b>","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=> "","col2"=>"Received the total amount","col3"=>"" },
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"<b>Operation Manager</b>", "col2"=>"<b>Branch Manager</b>","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"", "col2"=>"","col3"=>""},
          {"col1"=>"Charges Recevied", "col2"=>"<b>Denomination</b>","col3"=>""},
          {"col1"=>"", "col2"=>"500 x     =","col3"=>""},
          {"col1"=>"", "col2"=>"100 x     =","col3"=>""},
          {"col1"=>"", "col2"=>"50   x     =    ","col3"=>""},
          {"col1"=>"", "col2"=>"20   x     =    ","col3"=>""},
          {"col1"=>"<b>Signature (Accountant)</b>", "col2"=>"10   x     =    ","col3"=>""},
          {"col1"=>"", "col2"=>"5     x     =    ","col3"=>""},
        ]
        table2.column_order  = ["col1", "col3", "col2"]
        table2.show_lines    = :none
        table2.shade_rows    = :none
        table2.show_headings = false
        table2.shade_headings = true
        table2.orientation   = :center
        table2.position      = :center
        table2.title_font_size = 16
        table2.header_gap = 20
        table2.width = 500
        table2.render_on(pdf)
      end
      return pdf
    end
  
    def generate_receipt_labels_pdf(user_id, on_date)
      location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user_id)
      lendings        = location_facade.get_loans_administered(self.id, on_date).compact
      raise ArgumentError,"No loans for generate pdf" if lendings.blank?
      pdf = PDF::Writer.new(:orientation => :portrait, :paper => "A4")
      pdf.select_font "Times-Roman"
      return nil if lendings.blank?
      pdf.text "Suryoday Microfinance (P) Ltd.", :font_size => 18, :justification => :center
      pdf.text "Disbursed Loan Receipt", :font_size => 16, :justification => :center
      pdf.text("\n")
      lendings            = location_facade.get_loans_administered(self.id, on_date).compact
      lendings.each do |la|
        pdf.text('Receipt', :font_size => 14, :justification => :center)
        pdf.text("\n")
        pdf.rounded_rectangle(pdf.absolute_left_margin-5, pdf.y+pdf.top_margin-25, 530, 120, 5).stroke
        pdf.text("I/We received a loan of #{la.to_money[:disbursed_amount]} on date #{la.disbursal_date} from center #{la.administered_at_origin_location.name} of Suryoday Microfinance Pvt. LTD")
        pdf.text("\n")
        pdf.text("Borrower Name :- #{la.loan_borrower.counterparty.name}")
        pdf.text("\n")
        pdf.text("Borrower Sign. :------------------------------")
        pdf.text("\n")
        pdf.start_new_page if pdf.y < 120
      end
      return pdf
    end

    def generate_approve_loans_sheet_pdf(user_id, date = Date.today)
      date = Date.parse(date.to_s) if date.class != Date
      location_facade = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user_id)
      meeting_facade  = FacadeFactory.instance.get_instance(FacadeFactory::MEETING_FACADE, user_id)
      lendings        = location_facade.get_loans_administered(self.id, date).compact
      raise ArgumentError,"No loans exists for generate pdf" if lendings.blank?
      folder   = File.join(Merb.root, "doc", "pdfs", "company","centers","#{self.name}")
      FileUtils.mkdir_p(folder)
      filename = File.join(folder, "approve_loans_#{self.name}_#{Time.now}.pdf")
      pdf = PDF::Writer.new(:orientation => :landscape, :paper => "A4")
      pdf.select_font "Times-Roman"
      pdf.info.title = "approve_loans_#{self.name}_#{Time.now}"
      pdf.text "<b>Suryoday Micro Finance (P) Ltd.</b>", :font_size => 24, :justification => :center
      pdf.text "Approved Loans For #{self.name} on #{date}", :font_size => 20, :justification => :center
      pdf.text("\n")
      lendings            = lendings.select{|lending| lending.is_approved? }
      location_manage     = location_facade.location_managed_by_staff(self.id, date)
      staff_member_name   = location_manage.blank? ? 'No Managed' : location_manage.manager_staff_member.name
      meeting             = meeting_facade.get_meeting(self, date)
      meeting_status      = meeting.blank? ? 'No Meeting' : "#{meeting.meeting_time_begins_hours}:#{'%02d' % meeting.meeting_time_begins_minutes}"
      table1              = PDF::SimpleTable.new
      table1.data = [{"col1"=>"<b>Branch</b>", "col_s1"=>":", "col2"=>"#{self.name}", "col3"=>"<b>Center</b>", "col_s2"=>":", "col4"=>"#{self.name}"},
        {"col1"=>"<b>R.O Name</b>", "col_s1"=>":", "col2"=>"#{staff_member_name}", "col3"=>"<b>Date</b>","col_s2"=>":", "col4"=>"#{date}"},
        {"col1"=>"<b>Meeting Address</b>", "col_s1"=>":", "col2"=>"#{self.biz_location_address}", "col3"=>"<b>Time</b>","col_s2"=>":", "col4"=>"#{meeting_status}"},
      ]

      table1.column_order  = ["col1", "col_s1","col2", "col3","col_s2", "col4"]
      table1.show_lines    = :none
      table1.shade_rows    = :none
      table1.show_headings = false
      table1.shade_headings = true
      table1.orientation   = :center
      table1.position      = :center
      table1.heading_font_size = 16
      table1.font_size         = 14
      table1.header_gap = 20
      table1.width = 830
      table1.render_on(pdf)
      pdf.text("\n")
      table      = PDF::SimpleTable.new
      table.data = []
      tot_amount = MoneyManager.default_zero_money
      loan_row_count=1
      if lendings.blank?
        pdf.text "No Loans are exists on Approve state", :font_size => 20
      else
        lendings.each do |lending|
          installment_due = lending.scheduled_total_due(date)
          client        = lending.borrower
          client_name  = client.name unless client.blank?
          client_group = client.client_group.blank? ? 'Nothing' : client.client_group.name
          table.data.push({
              "S. No."        => loan_row_count,
              "Group"         => client_group,
              "Customer Name" => client_name,
              "Loan LAN No."  => lending.lan,
              "POS"           => '',
              "Inst. Date"    => '',
              "Inst. No."     => '',
              "Overdue"       => '',
              "Inst. Due"     => installment_due.to_s,
              "Inst. Paid"    => '',
              "Attendance"    => ''
            })
          loan_row_count += 1
          tot_amount += installment_due
        end
        table.data.push({"Group" => 'Total Amount', "Inst. Due" => tot_amount.to_s})
        table.column_order      = ["S. No.", "Group", "Loan LAN No.", "Customer Name", "POS", "Inst. No.", "Overdue", "Inst. Due", "Inst. Paid", "Attendance"]
        table.show_lines        = :all
        table.show_headings     = true
        table.shade_rows        = :none
        table.shade_headings    = true
        table.orientation       = :center
        table.position          = :center
        table.heading_font_size = 16
        table.font_size         = 12
        table.header_gap        = 10
        table.maximum_width     = 830
        table.columns["Loan LAN No."]  = PDF::SimpleTable::Column.new("Loan LAN No.")
        table.columns["Customer Name"] = PDF::SimpleTable::Column.new("Customer Name")
        table.columns["Inst. No."]     = PDF::SimpleTable::Column.new("Inst. No.")
        table.columns["POS"]           = PDF::SimpleTable::Column.new("POS")
        table.columns["Loan LAN No."].width  = 120
        table.columns["Inst. No."].width  = 50
        table.columns["Customer Name"].width  = 120
        table.columns["POS"].width  = 80
        table.render_on(pdf)
      end
      pdf.save_as(filename)
      pdf
    end

    def location_loan_product_receipts_pdf(user_id, on_date)
      location_facade  = FacadeFactory.instance.get_instance(FacadeFactory::LOCATION_FACADE, user_id)
      all_lendings     = location_facade.get_loans_administered(self.id, on_date).compact.select{|l| l.is_outstanding?}
      lendings_by_group = all_lendings.group_by{|l| l.lending_product}
      raise ArgumentError,"No loans exists for generate pdf" if all_lendings.blank?
      pdf              = PDF::Writer.new(:orientation => :portrait, :paper => "A4")
      pdf.select_font "Times-Roman"
      pdf.text "<b>Suryoday Micro Finance (P) Ltd.</b>", :font_size => 12, :justification => :left
      pdf.text "1101 Sharada Terraces, Plot 65, Sector 11,", :font_size => 12, :justification => :left
      pdf.text "CBD Belapur, Navi Mumbai - 400614", :font_size => 12, :justification => :left
      pdf.text("\n")
      pdf.text("Receipt", :font_size => 16, :justification => :center, :text_color=>'red')
      pdf.rounded_rectangle(pdf.absolute_left_margin+10, pdf.y+pdf.top_margin - 20, 500, 20, 5).stroke
      
      pdf.text("\n")
      table1              = PDF::SimpleTable.new
      table1.data = [{"col1"=>"<b>Date</b>", "col2"=>"", "col3"=>"<b>#{on_date}</b>"},
        {"col1"=>"<b>Center Name</b>", "col2"=>"", "col3"=>"<b>#{self.name}</b>"},
        {"col1"=>"<b>No. Of Members</b>", "col2"=>"", "col3"=>"<b>#{all_lendings.count}</b>"}
      ]

      table1.column_order  = ["col1", "col2", "col3"]
      table1.show_lines    = :none
      table1.shade_rows    = :none
      table1.show_headings = false
      table1.shade_headings = true
      table1.orientation   = :center
      table1.position      = :center
      table1.title_font_size = 16
      table1.header_gap = 20
      table1.width = 500
      table1.render_on(pdf)
      pdf.text("\n")
      pdf.text('Received the following charges from the members of the above center', :font_size => 12, :justification => :center)
      pdf.text("\n")
      count = 1

      if all_lendings.count > 0
        table      = PDF::SimpleTable.new
        table.data = []
        members    = 0
        tot_amount = MoneyManager.default_zero_money
        lendings   = []
        
        lendings_by_group.each do |lending_product, lendings|
          product_fee_amount = MoneyManager.default_zero_money
          total_fee_amount   = MoneyManager.default_zero_money
          fee_products       = FeeAdministration.get_lending_fee_products(lending_product)
          fee_instances      = lendings.blank? ? [] : FeeInstance.all_fee_instances_on_loan(lendings.map(&:id))
          product_name       = lending_product.name
          member             = lendings.blank? ? '-' : lendings.count
          fee_products.each{|f| product_fee_amount += f.effective_total_amount(Date.today, lending_product.to_money[:amount])}
          fee_instances.each{|f| total_fee_amount += f.total_money_amount}
          total              = lendings.blank? ? '-' : total_fee_amount.to_s

          table.data.push({'S. No.'=> count, "Loan Type"=> product_name, "Charges" => product_fee_amount.to_s, "  " => 'X', "No. of Members" => member,
              "Total" =>  total
            })
          count += 1
          tot_amount += total_fee_amount
          members  += lendings.count unless lendings.blank?
        end

        table.data.push({"S. No."=>"Total", "  " => 'X', "No. of Members" => members, "Total" =>  tot_amount.to_s})
        table.column_order  = ["S. No.", "Loan Type", "Charges", '  ', "No. of Members", "Total"]
        table.show_lines    = :all
        table.shade_rows    = :none
        table.show_headings = true
        table.shade_headings = true
        table.orientation   = :center
        table.position      = :center
        table.title_font_size = 16
        table.header_gap = 20
        table.width = 500
        table.render_on(pdf)
        pdf.start_new_page if pdf.y < 315
        pdf.text("\n")
        pdf.text("Amount In Word:_____________________________________")
        pdf.text("\n")
        pdf.text("\n")
        pdf.text("Branch Manager:_____________________________________")
        pdf.text("\n")
        pdf.text("\n")
        pdf.text("\n")
        pdf.text("Signature")
        return pdf
      end

    end
  end
end
