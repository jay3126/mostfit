module Pdf
  module DaySheet

    def generate_collection_pdf(date)
      folder   = File.join(Merb.root, "doc", "pdfs", "staff", self.name, "collection_sheets")
      FileUtils.mkdir_p(folder)
      filename = File.join(folder, "collection_#{self.id}_#{date.strftime('%Y_%m_%d')}.pdf")
      center_ids = LoanHistory.all(:date => [date, date.holidays_shifted_today].uniq, :fields => [:loan_id, :date, :center_id], :status => [:disbursed, :outstanding]).map{|x| x.center_id}.uniq
      centers = self.centers(:id => center_ids).sort_by{|x| x.name}
      pdf = PDF::Writer.new(:orientation => :landscape, :paper => "A4")
      pdf.select_font "Times-Roman"
      return nil if centers.empty?
      days_absent = Attendance.all(:status => "absent", :center => centers).aggregate(:client_id, :all.count).to_hash
      days_present = Attendance.all(:center => centers).aggregate(:client_id, :all.count).to_hash
      centers.sort_by{|x| x.meeting_time_hours*60 + x.meeting_time_minutes}.each_with_index{|center, idx|
        pdf.start_new_page if idx > 0
        pdf.text "Daily Collection Sheet for #{self.name} for #{date}", :font_size => 11, :justification => :center
        pdf.text("\n")
        pdf.text "Branch:  #{center.branch.name}, Center:   #{center.name},  Center Manager: #{self.name},  signature: ______________________", :font_size => 10, :justification => :left
        pdf.text("Center leader:   #{center.leader.client.name},   signature: ______________________", :font_size => 10, :justification => :left) if center.leader
        pdf.text("Date: #{date}, Time: #{center.meeting_time_hours}:#{'%02d' % center.meeting_time_minutes}", :font_size => 12, :justification => :left)
        pdf.text("\n")
        table = PDF::SimpleTable.new
        table.data = []
        tot_amount, tot_outstanding, tot_installments, tot_principal, tot_interest, total_due = 0, 0, 0, 0, 0, 0
        #Prefecth some data for speed
        loans = center.loans
        puts "#{center.name} : #{loans.aggregate(:id)}"
        histories = LoanHistory.all(:loan_id => loans.map{|x| x.id}, :date => date)
        fees_applicable = Fee.due(loans.map{|x| x.id})
        tot_amount, tot_outstanding, tot_installments, tot_principal, tot_interest, tot_fee, tot_total = 0, 0, 0, 0, 0, 0, 0

        #grouping by client groups
        center.clients(:fields => [:id, :name]).group_by{|x| x.client_group}.sort_by{|x| x[0] ? x[0].name : "none"}.each{|group, clients|
          group_amount, group_outstanding, group_installments, group_principal, group_interest, group_fee, group_due = 0, 0, 0, 0, 0, 0, 0
          table.data.push({"disbursed" => group ? group.name : "No group"})
          #absent days
          #Grouped clients
          clients.sort_by{|x| x.id}.each{|client|
            # all the loans of a client
            loan_row_count=0
            loans.find_all{|l| l.client_id==client.id and l.disbursal_date}.each{|loan|
              lh = histories.find_all{|x| x.loan_id==loan.id}.sort_by{|x| x.created_at}[-1]
              next if not lh
              next if LOANS_NOT_PAYABLE.include? lh.status
              loan_row_count+=1
              #fee = fees_applicable[loan.id] ? fees_applicable[loan.id].due : 0
              fee = loan.total_fees_payable_on(date) || 0
              actual_outstanding = (lh ? lh.actual_outstanding_principal : 0)
              principal_due      = [(lh ? lh.principal_due : 0), 0].max
              interest_due       = [(lh ? lh.interest_due : 0), 0].max
              total_due          = [(lh ? (fee+lh.principal_due+lh.interest_due): 0), 0].max
              number_of_installments = loan.number_of_installments_before(date)

              table.data.push({"name" => client.name, "loan id" => loan.id, "amount" => loan.amount.to_currency,
                  "outstanding" => actual_outstanding.to_currency, "status" => lh.status.to_s,
                  "disbursed" => loan.disbursal_date.to_s, "installment" =>  number_of_installments,
                  "principal" => principal_due.to_currency, "interest" => interest_due.to_currency, "days absent/total" => (days_absent[client.id]||0).to_s / (days_present[client.id]||0).to_s,"fee" => fee.to_currency, "total due" =>  total_due.to_currency, "signature" => "" })
              group_amount       += loan.amount
              group_outstanding  += actual_outstanding
              group_installments += number_of_installments
              group_principal    += principal_due
              group_interest     += interest_due
              group_fee          += fee
              group_due          += total_due
            } # loans end
            if loan_row_count==0
              table.data.push({"name" => client.name, "signature" => "", "status" => "nothing outstanding"})
            end
          } #clients end
          table.data.push({"amount" => group_amount.to_currency, "outstanding" => group_outstanding.to_currency,
                            "principal" => group_principal.to_currency, "interest" => group_interest.to_currency,
                            "fee" => group_fee.to_currency, "total due" => group_due.to_currency
                          })
          tot_amount         += group_amount
          tot_outstanding    += group_outstanding
          tot_installments   += group_installments
          tot_principal      += group_principal
          tot_interest       += group_interest
          tot_fee            += group_fee
          total_due          += (group_principal + group_interest + group_fee)
        } #groups end
        table.data.push({"amount" => tot_amount.to_currency, "outstanding" => tot_outstanding.to_currency,
                          "principal" => tot_principal.to_currency,
                          "interest" => tot_interest.to_currency, "fee" => tot_fee.to_currency,
                          "total due" => (tot_principal + tot_interest + tot_fee).to_currency
                        })

        table.column_order  = ["name", "loan id" , "amount", "outstanding", "status", "disbursed", "installment", "principal", "interest", "fee", "total due", "days absent/total", "signature"]
        table.show_lines    = :all
        table.show_headings = true
        table.shade_rows    = :none
        table.shade_headings = true
        table.orientation   = :center
        table.position      = :center
        table.title_font_size = 10
        table.header_gap = 10
        table.render_on(pdf)

        #draw table for scheduled disbursals
        loans_to_disburse = center.clients.loans(:scheduled_disbursal_date => date)
        if center.clients.count>0 and loans_to_disburse.count > 0
          table = PDF::SimpleTable.new
          table.data = []

          loans_to_disburse.each do |loan|
            table.data.push({"amount" => loan.amount.to_currency, "name" => loan.client.name,
                "group" => (loan.client.client_group or Nothing).name,
                "loan product" => loan.loan_product.name, "first payment" => loan.scheduled_first_payment_date                              ,"spouse name" => loan.client.spouse_name
              })
          end
          table.column_order  = ["name", "spouse name", "group", "amount", "loan product", "first payment", "signature    "]
          table.show_lines    = :all
          table.shade_rows    = :none
          table.show_headings = true
          table.shade_headings = true
          table.orientation   = :center
          table.position      = :center
          table.title_font_size = 10
          table.header_gap = 10
          pdf.text("\n")
          pdf.text "Disbursements today"
          pdf.text("\n")
          table.render_on(pdf)
        end
      } #centers end
      pdf.save_as(filename)
      return pdf
    end

    def generate_disbursement_pdf(date)
      folder   = File.join(Merb.root, "doc", "pdfs", "staff", self.name, "disbursement_sheets")
      FileUtils.mkdir_p(folder)
      filename = File.join(folder, "disbursement.pdf")
      center_ids = Loan.all(:scheduled_disbursal_date => date, :approved_on.not => nil, :rejected_on => nil).map{|x| x.client.center_id}.uniq
      centers = self.centers(:id => center_ids).sort_by{|x| x.name}

      pdf = PDF::Writer.new(:orientation => :portrait, :paper => "A4")
      pdf.select_font "Times-Roman"
      return nil if centers.empty?
      centers.sort_by{|x| x.meeting_time_hours*60 + x.meeting_time_minutes.to_i}.each_with_index{|center, idx|
        pdf.start_new_page if idx > 0
        pdf.text "Suryoday Microfinance (P) Ltd.", :font_size => 18, :justification => :center
        pdf.text "Disbursal Report and Acknowledgement", :font_size => 16, :justification => :center
        pdf.text("\n")
        table1 = PDF::SimpleTable.new
        table1.data = [{"col1"=>"<b>Center</b>", "col2"=>"#{center.name}", "col3"=>"<b>No. of Members</b>", "col4"=>"#{center.clients.count}"},
          {"col1"=>"<b>R.O Name</b>", "col2"=>"#{center.manager.name}", "col3"=>"<b>Disbursal Date</b>", "col4"=>"#{date}"},
          {"col1"=>"<b>Meeting Address</b>", "col2"=>"#{center.address}", "col3"=>"<b>Time</b>", "col4"=>"#{center.meeting_time_hours}:#{'%02d' % center.meeting_time_minutes}"}
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
        loans_to_disburse = center.clients.loans(:scheduled_disbursal_date => date) #, :disbursal_date => nil, :approved_on.not => nil, :rejected_on => nil)
        if center.clients.count>0 and loans_to_disburse.count > 0
          table = PDF::SimpleTable.new
          table.data = []
          tot_amount = 0
          loans_to_disburse.each do |loan|
            tot_amount += loan.amount
            table.data.push({"LAN"=> loan.id,"Disb. Amount" => loan.amount.to_currency, "Name" => loan.client.name,
                "Group" => (loan.client.client_group or Nothing).name
              })
          end
          table.data.push({"Group"=>"Total=#{loans_to_disburse.count}","Disb. Amount" => tot_amount.to_currency})
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
