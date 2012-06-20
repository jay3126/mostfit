module Pdf
  module DaySheet

    def generate_collection_pdf(date)
      folder   = File.join(Merb.root, "doc", "pdfs", "staff", self.name, "collection_sheets")
      FileUtils.mkdir_p(folder)
      filename = File.join(folder, "collection_#{self.id}_#{date.strftime('%Y_%m_%d')}.pdf")
      # center_ids = LoanHistory.all(:date => [date, date.holidays_shifted_today].uniq, :fields => [:loan_id, :date, :center_id], :status => [:disbursed, :outstanding]).map{|x| x.center_id}.uniq
      # centers = self.centers(:id => center_ids).sort_by{|x| x.name}
      @biz_locations = LocationManagement.get_locations_for_staff(self, date)
      pdf = PDF::Writer.new(:orientation => :landscape, :paper => "A4")
      pdf.select_font "Times-Roman"
      pdf.text "Daily Collection Sheet for #{self.name} for #{date}", :font_size => 24, :justification => :center
      pdf.text("\n")
      #return nil if centers.empty?
      return nil if @biz_locations.empty?
      #days_absent = Attendance.all(:status => "absent", :center => centers).aggregate(:client_id, :all.count).to_hash
      #days_present = Attendance.all(:center => centers).aggregate(:client_id, :all.count).to_hash
      weeksheets = CollectionsFacade.new(self.id).get_collection_sheet_for_staff(date)
      idx = 0
      weeksheets.each do |weeksheet|
        unless weeksheet.blank?
          location = BizLocation.get weeksheet.at_biz_location_id
          pdf.start_new_page if idx > 0
          pdf.text "Location: #{location.name}, Manager: #{self.name}, signature: ______________________", :font_size => 12, :justification => :left
          #pdf.text("Center leader: #{location.leader.client.name}, signature: ______________________", :font_size => 12, :justification => :left) if location.leader
          pdf.text("Date: #{date}, Time: #{weeksheet.at_meeting_time_begins_hours}:#{'%02d' % weeksheet.at_meeting_time_begins_minutes}", :font_size => 12, :justification => :left)
          pdf.text("Meeting Status: No Meeting", :font_size => 12, :justification => :left) unless MeetingCalendar.meeting_at_location_on_date(location, date)
          pdf.text("\n")

          table = PDF::SimpleTable.new
          table.data = []
          tot_amount, tot_outstanding, tot_installments, tot_principal, tot_interest, total_due, tot_fee= 0, 0, 0, 0, 0, 0, 0
          weeksheet.groups.each do |group|
            collection_sheets = weeksheet.collection_sheet_lines.select{|cs| cs.borrower_group_id == group[0]}.sort_by{|cs| cs.borrower_name} rescue []
            group_amount, group_outstanding, group_installments, group_principal, group_interest, group_fee, group_due = 0, 0, 0, 0, 0, 0, 0
            #table.data.push({"Actual Principal Due" => group ? group[1] : "No group"})
            loan_row_count=0
            collection_sheets.each do |ws|
              table.data.push({
                  "Name"                         => ws.borrower_name,
                  "Loan Id"                      => ws.loan_id,
                  "Status"                       => ws.loan_status.to_s.humanize,
                  "Disbursed Amount"             => ws.loan_disbursed_amount.to_s,
                  "Disbursed Date"               => ws.loan_disbursed_date,
                  "Installment Number"           => ws.loan_installment_number,
                  "Schedule Date"                => ws.loan_schedule_date,
                  "Due Status"                   => ws.loan_due_status.to_s.humanize,
                  "Days Past Due"                => ws.loan_days_past_due,
                  "Schedule Principal Due"       => ws.loan_schedule_principal_due.to_s,
                  "Actual Principal Due"         => ws.loan_actual_principal_due.to_s,
                  "Actual Principal Outstanding" => ws.loan_actual_principal_outstanding.to_s,
                  "Schedule Interest Due"        => ws.loan_schedule_interest_due.to_s,
                  "Actual Interest Due"          => ws.loan_actual_interest_due.to_s,
                  "Actual Interest Outstanding"  => ws.loan_actual_interest_outstanding.to_s,
                  "Advance Amount"               => ws.loan_advance_amount.to_s,
                  "Principal Receipts"           => ws.loan_principal_receipts.to_s,
                  "Interest Receipts"            => ws.loan_interest_receipts.to_s,
                  "Advance Receipts"             => ws.loan_advance_receipts.to_s,
                  "Total Amount"                 => ws.total_amount_to_be_paid.to_s,
                  "Signature" => "" })
              loan_row_count     += 1
              if loan_row_count==0
                table.data.push({"Name" => ws.borrower_name, "Signature" => "", "Status" => "nothing outstanding"})
              end
            end

            #          table.data.push({"amount" => group_amount.to_currency, "outstanding" => group_outstanding.to_currency,
            #              "principal" => group_principal.to_currency, "interest" => group_interest.to_currency,
            #              "fee" => group_fee.to_currency, "total due" => group_due.to_currency
            #            })
            #          tot_amount         += group_amount
            #          tot_outstanding    += group_outstanding
            #          tot_installments   += group_installments
            #          tot_principal      += group_principal
            #          tot_interest       += group_interest
            #          tot_fee            += group_fee
            #          total_due          += (group_principal + group_interest + group_fee)

          end
          #        table.data.push({"amount" => tot_amount.to_currency, "outstanding" => tot_outstanding.to_currency,
          #            "principal" => tot_principal.to_currency,
          #            "interest" => tot_interest.to_currency, "fee" => tot_fee.to_currency,
          #            "total due" => (tot_principal + tot_interest + tot_fee).to_currency
          #          })
          #table.column_order  = ["name", "loan id" , "amount", "outstanding", "status", "disbursed", "installment", "principal", "interest", "fee", "total due", "days absent/total", "signature"]
          table.column_order  = ["Name", "Loan Id" ,"Status","Disbursed Amount","Disbursed Date","Installment Number",
            "Schedule Date","Due Status","Days Past Due","Schedule Principal Due",
            "Actual Principal Due","Actual Principal Outstanding","Schedule Interest Due",
            "Actual Interest Due","Actual Interest Outstanding","Advance Amount",
            "Principal Receipts","Interest Receipts","Advance Receipts",
            "Total Amount", "Signature"]
          table.show_lines        = :all
          table.show_headings     = true
          table.shade_rows        = :none
          table.shade_headings    = true
          table.orientation       = :center
          table.position          = :center
          table.heading_font_size = 8
          table.font_size         = 8
          table.header_gap        = 10
          table.maximum_width     = 830
          table.render_on(pdf)

          idx += 1
        end
      end
      pdf.save_as(filename)
      return pdf
    end

    def generate_disbursement_pdf(date)
      folder   = File.join(Merb.root, "doc", "pdfs", "staff", self.name, "disbursement_sheets")
      FileUtils.mkdir_p(folder)
      filename = File.join(folder, "disbursement_#{self.id}_#{date.strftime('%Y_%m_%d')}.pdf")
      center_ids = Loan.all(:scheduled_disbursal_date => date, :approved_on.not => nil, :rejected_on => nil).map{|x| x.client.center_id}.uniq
      centers = self.centers(:id => center_ids).sort_by{|x| x.name}

      pdf = PDF::Writer.new(:orientation => :landscape, :paper => "A4")
      pdf.select_font "Times-Roman"
      pdf.text "Daily Disbursement Sheet for #{self.name} for #{date}", :font_size => 24, :justification => :center
      pdf.text("\n")
      return nil if centers.empty?   
      days_absent = Attendance.all(:status => "absent", :center => centers).aggregate(:client_id, :all.count).to_hash
      centers.sort_by{|x| x.meeting_time_of_day}.each_with_index{|center, idx|
        pdf.start_new_page if idx > 0
        pdf.text "Center: #{center.name}, Manager: #{self.name}, signature: ______________________", :font_size => 12, :justification => :left
        pdf.text("Center leader: #{center.leader.client.name}, signature: ______________________", :font_size => 12, :justification => :left) if center.leader
        pdf.text("Date: #{date}, Time: #{center.meeting_time_hours}:#{'%02d' % center.meeting_time_minutes}", :font_size => 12, :justification => :left)
        pdf.text("Actual Disbursement on ___________________________, signature: ______________________", :font_size => 12, :justification => :left)
        pdf.text("\n")
        #draw table for scheduled disbursals
        loans_to_disburse = center.clients.loans(:scheduled_disbursal_date => date) #, :disbursal_date => nil, :approved_on.not => nil, :rejected_on => nil)
        if center.clients.count>0 and loans_to_disburse.count > 0
          table = PDF::SimpleTable.new
          table.data = []
          tot_amount = 0
          loans_to_disburse.each do |loan|
            tot_amount += loan.amount
            premia, amount_to_disburse = 0, nil
            if loan.loan_product.linked_to_insurance
              premia = loan.insurance_policy.premium
              amount_to_disburse = loan.amount - loan.insurance_policy.premium
            else
              premia = "NA"
            end
            table.data.push({"amount" => loan.amount.to_currency, "name" => loan.client.name,
                "group" => (loan.client.client_group or Nothing).name,
                "loan product" => loan.loan_product.name, "first payment" => loan.scheduled_first_payment_date,
                "spouse name" => loan.client.spouse_name, "loan status" => loan.status,
                "insurance premium" => premia, "balance to disburse" => (amount_to_disburse||loan.amount.to_currency)
              })
          end
          table.data.push({"amount" => tot_amount.to_currency})
          table.column_order  = ["name", "spouse name",  "group", "amount", "insurance premium", "balance to disburse", "loan product", "first payment", "loan status", "signature"]
          table.show_lines    = :all
          table.shade_rows    = :none
          table.show_headings = true          
          table.shade_headings = true
          table.orientation   = :center
          table.position      = :center
          table.title_font_size = 16
          table.header_gap = 20
          pdf.text("\n")
          pdf.text "Disbursements today"
          pdf.text("\n")
          table.render_on(pdf)
        end        
      } #centers end
      pdf.save_as(filename)
      return pdf
    end
    def generate_weeksheet_pdf(center, date)
      weeksheet_rows = Weeksheet.get_center_weeksheet(center, date, "data") if center
      if not weeksheet_rows.blank?
        pdf = PDF::Writer.new(:orientation => :landscape, :paper => "A4")
        pdf.select_font "Times-Roman"
        pdf.text "Weeksheet of #{center.name} for #{date}", :font_size => 24, :justification => :center
        pdf.text("\n")
        pdf.text "Center: #{center.name}, Manager: #{center.manager.name}, signature: ______________________", :font_size => 12, :justification => :left
        pdf.text("Center leader: #{center.leader.client.name}, signature: ______________________", :font_size => 12, :justification => :left) if center.leader
        pdf.text("Date: #{date}, Time: #{center.meeting_time_hours}:#{'%02d' % center.meeting_time_minutes}", :font_size => 12, :justification => :left)
        pdf.text("\n")
        table = PDF::SimpleTable.new
        table.data = []
        old_group = ""
        weeksheet_rows.each do |row|
          table.data.push({"disbursed on" => row.client_group_name}) if old_group != row.client_group_name
          table.data.push({"name" => row.client_name, "loan id" => row.loan_id, "amount" => row.loan_amount.to_currency,
              "outstanding" => row.outstanding.to_currency, "disbursed on" => row.disbursal_date.to_s, "installment" =>  row.installment,
              "principal due" => row.principal.to_currency, "interest due" => row.interest.to_currency, "total due" =>  row.principal + row.interest, "signature" => "" })
          old_group = row.client_group_name
        end
        table.column_order  = ["name", "loan id" , "amount", "outstanding", "disbursed on", "installment", "principal due", "interest due",  "total due", "signature"]
        table.show_lines    = :all
        table.show_headings = true
        table.shade_rows    = :none
        table.shade_headings = true
        table.orientation   = :center
        table.position      = :center
        table.title_font_size = 16
        table.header_gap = 10
        table.render_on(pdf)

        pdf.save_as("#{Merb.root}/public/pdfs/weeksheet_of_center_#{center.id}_#{date.strftime('%Y_%m_%d')}.pdf")
        return pdf
      end
    end
  end
  
  module LoanSchedule
    def generate_loan_schedule
      loan_history = self.loan_history
      return nil if loan_history.empty?
      pdf =  PDF::Writer.new(:orientation => :portrait, :paper => "A4")
      pdf.select_font "Times-Roman"
      pdf.text "Repayment Schedule of Loan ID #{self.id} for client #{self.client.name} (ID: #{self.id})", :font_size => 18, :justification => :center
      pdf.text("\n")
      client_info = PDF::SimpleTable.new
      client_info.data = []
      client_info.data.push({ "identifier" => "Amount Applied", "value" => "#{self.amount_applied_for.to_currency } by #{self.applied_by.name} on #{self.applied_on.strftime("%d-%m-%Y")}"},
        { "identifier" => "Amount Sanctioned", "value" => "#{self.amount_sanctioned.to_currency} by #{self.approved_by.name} on #{self.approved_on.strftime("%d-%m-%Y")}"},
        { "identifier" => "Amount Disbursed", "value" => "#{self.amount.to_currency} by #{self.disbursed_by.name} on #{self.disbursal_date.strftime("%d-%m-%Y")}"},
        { "identifier" => "Loan Product", "value" => self.loan_product.name },
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
        scheduled_principal = lh[:scheduled_principal_to_be_paid] == 0 ? (i > 0 ? loan_history[i-1].scheduled_outstanding_principal - lh.scheduled_outstanding_principal : 0) : lh[:scheduled_principal_to_be_paid]
        scheduled_interest =  lh[:scheduled_interest_to_be_paid] == 0 ? (i > 0 ? loan_history[i-1].scheduled_outstanding_total - lh.scheduled_outstanding_total - scheduled_principal : 0) : lh[:scheduled_interest_to_be_paid]
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
  end

end
