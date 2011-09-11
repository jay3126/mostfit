module Mostfit
  module PaymentStyles

    module EquatedWeeklyRoundedNewInterest
      # This loan product recalculates interest based on the new balances after rounding.
      include ExcelFormula
      # property :purpose,  String

      def self.display_name
        "Reducing balance schedule with new interest (Equated Weekly)"
      end

      def scheduled_principal_for_installment(number)
        # number unused in this implentation, subclasses may decide differently
        # therefor always supply number, so it works for all implementations
        raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > number_of_installments
        return reducing_schedule[number][:principal_payable]
      end

      def scheduled_interest_for_installment(number)  # typically reimplemented in subclasses
        # number unused in this implentation, subclasses may decide differently
        # therefor always supply number, so it works for all implementations
        raise "number out of range, got #{number}" if number < 0 or number > number_of_installments
        return reducing_schedule[number][:interest_payable]
      end

      def equated_payment
        payment            = pmt(interest_rate/get_divider, number_of_installments, amount, 0, 0)
        rnd = loan_product.rounding || 1
        (payment / rnd).send(loan_product.rounding_style) * rnd
      end    
      
      def pay_prorata(total, received_on, curr_bal = nil)
        #adds up the principal and interest amounts that can be paid with this amount and prorates the amount
        i = used = prin = int = 0.0
        d = received_on
        total = total.to_f
        prin_due = info(d)[:principal_due]
        int_due  = info(d)[:interest_due]
        if prin_due and int_due
          prin = prin_due
          int = int_due
          used += (int + prin)
        end
        while used < total
          prin += scheduled_principal_for_installment(installment_for_date(d)).round(2)
          int  += scheduled_interest_for_installment(installment_for_date(d)).round(2)
          used  = (prin + int)
          d = shift_date_by_installments(d, 1)
        end
        interest  = total * int/(prin + int)
        principal = total * prin/(prin + int)
        [interest, principal]
      end


      private
      def reducing_schedule
        return @reducing_schedule if @reducing_schedule
        @reducing_schedule = {}    
        balance = amount
        actual_payment = equated_payment
        1.upto(number_of_installments){|installment|
          @reducing_schedule[installment] = {}
          @reducing_schedule[installment][:interest_payable]  = ((balance * interest_rate) / get_divider)
          @reducing_schedule[installment][:principal_payable] = [(actual_payment - @reducing_schedule[installment][:interest_payable]), balance].min
          balance = balance - @reducing_schedule[installment][:principal_payable]
        }
        return @reducing_schedule
      end

      def get_divider
        case installment_frequency
        when :weekly
          52
        when :biweekly
          26
        when :fortnightly
          26
        when :monthly
          12
        when :daily
          365
        end    
      end
    end


    module DairyLoan
      
      def self.display_name
        "Dairy Loan with Attached Insurance product"
      end
      
      def get_total_for_installment(number)
        case amount
        when 16000
          number < number_of_installments ? 415 : 350
        when 18000
          number < number_of_installments ? 470 : 190
        when 20000
          number < number_of_installments ? 520 : 360
        else
          0
        end
      end

      def installment_dates
        insts = reducing_schedule.count
        return @_installment_dates if @_installment_dates
        if installment_frequency == :daily
          # we have to br careful that when we do a holiday bump, we do not get stuck in an endless loop
          ld = scheduled_first_payment_date - 1
          @_installment_dates = []
          (1..insts).each do |i|
            ld += 1
            if ld.cwday == weekly_off
              ld +=1
            end
            if ld.holiday_bump.cwday == weekly_off # endless loop
              ld.holiday_bump(:after)
            end
            @_installment_dates << ld
          end
          return @_installment_dates
        end
        
        ensure_meeting_day = false
        ensure_meeting_day = [:weekly, :biweekly].include?(installment_frequency)
        ensure_meeting_day = true if self.loan_product.loan_validations and self.loan_product.loan_validations.include?(:scheduled_dates_must_be_center_meeting_days)
        @_installment_dates = (0..(insts-1)).to_a.map {|x| shift_date_by_installments(scheduled_first_payment_date, x, ensure_meeting_day) } 
        scheduled_last_payment_date = ((disbursal_date || scheduled_disbursal_date) >> 24) + 1
        #to check whether the day is sunday or not. Done on Intellecash request.
        if (scheduled_last_payment_date.strftime("%A") == "Sunday")
          scheduled_last_payment_date += 1
        else
          scheduled_last_payment_date
        end
        @_installment_dates[-1] = scheduled_last_payment_date
        return @_installment_dates
      end

      def reducing_schedule
        return @reducing_schedule if @reducing_schedule
        @reducing_schedule = {}    
        balance = amount
        1.upto(number_of_installments){|installment|
          @reducing_schedule[installment] = {}
          @reducing_schedule[installment][:interest_payable]  = ((balance * interest_rate) / get_divider)
          @reducing_schedule[installment][:total_payable]     = get_total_for_installment(installment)
          @reducing_schedule[installment][:principal_payable] = @reducing_schedule[installment][:total_payable] - @reducing_schedule[installment][:interest_payable]
          if installment == number_of_installments
            tp  = get_total_for_installment(installment)
            @reducing_schedule[installment][:total_payable]   = tp
            @reducing_schedule[installment][:principal_payable] = balance
            @reducing_schedule[installment][:interest_payable] = tp - balance
          end
          balance = balance - @reducing_schedule[installment][:principal_payable]
          if (installment == 26)
            balance += self.insurance_policy.premium 
          end

        }
        return @reducing_schedule
      end    
      
      def payment_schedule
        # this is the fount of all knowledge regarding the scheduled payments for the loan. 
        # it feeds into every other calculation about the loan schedule such as get_scheduled, calculate_history, etc.
        # if this is wrong, everything about this loan is wrong.
        return @schedule if @schedule
        @schedule = {}
        return @schedule unless amount.to_f > 0

        #if self.respond_to?(:repayment_style) and self.repayment_style
        #  extend Kernel.module_eval("Mostfit::RepaymentStyles:#{repayment_style.camel_case}")
        #end

        principal_so_far = interest_so_far = fees_so_far = total = 0
        balance = amount
        fs = fee_schedule
        dd = disbursal_date || scheduled_disbursal_date
        fees_so_far = fs.has_key?(dd) ? fs[dd].values.inject(0){|a,b| a+b} : 0

        @schedule[dd] = {:principal => 0, :interest => 0, :total_principal => 0, :total_interest => 0, :balance => balance, :total => 0, :fees => fees_so_far}

        repayed =  false

        ensure_meeting_day = false
        # commenting this code so that meeting dates not automatically set
        #ensure_meeting_day = [:weekly, :biweekly].include?(installment_frequency)
        ensure_meeting_day = true if self.loan_product.loan_validations and self.loan_product.loan_validations.include?(:scheduled_dates_must_be_center_meeting_days)
        (1..actual_number_of_installments).each do |number|
          date      = installment_dates[number-1] #shift_date_by_installments(scheduled_first_payment_date, number - 1, ensure_meeting_day)
          principal = scheduled_principal_for_installment(number)
          interest  = scheduled_interest_for_installment(number)
          next if repayed
          repayed   = true if amount <= principal_received_up_to(date)
          
          principal_so_far += principal
          interest_so_far  += interest
          fees = fs.has_key?(date) ? fs[date].values.inject(0){|a,b| a+b} : 0
          fees_so_far += fees || 0
          balance -= principal
          if number == 26
            balance += self.insurance_policy.premium
          end
          puts "#{balance} : #{principal} : #{interest}"
          @schedule[date] = {
            :principal                  => principal,
            :interest                   => interest,
            :fees                       => fees,
            :total_principal            => principal_so_far,
            :total_interest             => interest_so_far,
            :total                      => (principal_so_far + interest_so_far),
            :balance                    => balance
          }
        end
        # we have to do the following to avoid the circular reference from total_to_be_received.
        total = @schedule[@schedule.keys.max][:total]
        @schedule.each { |k,v| v[:total_balance] = (total - v[:total]).round(2)}
        @schedule
      end

      def payments_hash
        # this is the fount of knowledge for actual payments on the loan
        return @payments_cache if @payments_cache
        sql = %Q{
        SELECT SUM(amount * IF(type=1,1,0)) AS principal,
               SUM(amount * IF(type=2,1,0)) AS interest,
               received_on
        FROM payments
        WHERE (deleted_at IS NULL) AND (loan_id = #{self.id})
        GROUP BY received_on ORDER BY received_on}
        structs = id ? repository.adapter.query(sql) : []
        @payments_cache = {}
        total_balance = total_to_be_received
        @payments_cache[disbursal_date || scheduled_disbursal_date] = {
          :principal => 0, :interest => 0, :total_principal => 0, :total_interest => 0, :total => 0, :balance => amount, :total_balance => total_balance
        }
        principal, interest, total = 0, 0, 0
        structs.each do |payment|
          # we know the received_on dates are in ascending order as we
          # walk through (so we can do the += thingy)
          @payments_cache[payment.received_on] = {
            :principal                 => payment.principal,
            :interest                  => payment.interest,
            :total_principal           => (principal += payment.principal),
            :total_interest            => (interest  += payment.interest),
            :total                     => (total     += payment.principal + payment.interest),
            :balance                   => (installment_for_date(payment.received_on) == 26 ? amount - principal + 960 : amount - principal),
            :total_balance             => total_balance - total}
        end

        # if the number of actual payments is less than the number of scheduled payments pad the rest of the array with zeroes
        dates = (installment_dates + payment_dates)
        dates = dates.uniq.sort.reject{|d| d <= structs[-1].received_on} unless structs.blank?
        dates.each do |date|
          @payments_cache[date] = {:principal => 0, :interest => 0, :total_principal => principal, :total_interest => interest, :total => total, :balance => amount - principal, :total_balance => total_balance - total}
        end
        @payments_cache
      end
      
      def scheduled_principal_for_installment(number)
        raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > number_of_installments
        return reducing_schedule[number][:principal_payable]
      end
      
      def scheduled_interest_for_installment(number)
        raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > number_of_installments
        return reducing_schedule[number][:interest_payable]
      end

      def pay_prorata(total, received_on, curr_bal = nil)
        #adds up the principal and interest amounts that can be paid with this amount and prorates the amount
        i = used = prin = int = 0.0
        d = received_on
        total = total.to_f
        prin_due = info(d)[:principal_due]
        int_due  = info(d)[:interest_due]
        if prin_due and int_due
          prin = prin_due
          int = int_due
          used += (int + prin)
        end
        while used < total
          prin += scheduled_principal_for_installment(installment_for_date(d)).round(2)
          int  += scheduled_interest_for_installment(installment_for_date(d)).round(2)
          used  = (prin + int)
          d = shift_date_by_installments(d, 1)
        end
        interest  = total * int/(prin + int)
        principal = total * prin/(prin + int)
        [interest, principal]
      end



    end

  end
end

