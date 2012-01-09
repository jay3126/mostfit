module Mostfit
  module PaymentStyles

    module EquatedWeeklyRoundedAdjustedLastPayment
      # This loan product uses the original interest amounts as per the PMT funtion and adjusts principal accordingly.
      include ExcelFormula
      # property :purpose,  String

      def self.display_name
        "Equated with rounding, preserving old interest"
      end

      def scheduled_principal_for_installment(number)
        # number unused in this implentation, subclasses may decide differently
        # therefor always supply number, so it works for all implementations
        raise "number out of range, got #{number} but max is #{number_of_installments}" if number < 0 or number > actual_number_of_installments
        return reducing_schedule[number][:principal_payable]
      end

      def scheduled_interest_for_installment(number)  # typically reimplemented in subclasses
        # number unused in this implentation, subclasses may decide differently
        # therefor always supply number, so it works for all implementations
        raise "number out of range, got #{number}" if number < 0 or number > actual_number_of_installments
        return reducing_schedule[number][:interest_payable]
      end

      def actual_number_of_installments
        reducing_schedule.count
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
      end

      def equated_payment
        payment = pmt(interest_rate/get_divider, number_of_installments, amount, 0, 0)
        #rnd = rs.round_total_to
        #actual_payment = (payment / rnd).send(rs.rounding_style) * rnd
        actual_payment = payment.round_to_nearest(rs.round_total_to, rs.rounding_style)
      end

      def pay_prorata(total, received_on, curr_bal = nil)
        i = used = prin = int = 0.0
        d = received_on
        total = total.to_f
        pmnt = equated_payment
        d = received_on
        curr_bal ||= actual_outstanding_principal_on(d)
        while (total - used) >= 0.01
          i_pmt = interest_calculation(curr_bal)
          int += i_pmt
          p_pmt = pmnt - i_pmt
          prin += p_pmt
          curr_bal -= p_pmt
          used  = (prin + int)
          d = shift_date_by_installments(d, 1)
        end
        interest  = total * int/(prin + int)
        principal = total * prin/(prin + int)
        [interest, principal]
      end


      private
      def reducing_schedule
        return @rounded_schedule if @rounded_schedule
        @reducing_schedule = {}    
        balance = amount
        payment            = pmt(interest_rate/get_divider, number_of_installments, amount, 0, 0)
        1.upto(number_of_installments){|installment|
          @reducing_schedule[installment] = {}
          @reducing_schedule[installment][:interest_payable]  = ((balance * interest_rate) / get_divider)
          if installment == number_of_installments or balance < (payment - @reducing_schedule[installment][:interest_payable])
            @reducing_schedule[installment][:principal_payable] = balance
          else
            @reducing_schedule[installment][:principal_payable] = (payment - @reducing_schedule[installment][:interest_payable])
          end
          balance = balance - @reducing_schedule[installment][:principal_payable]
        }
        done = false
        i = 1
        @rounded_schedule = {}
        balance = amount
        actual_payment = equated_payment
        while not done
          @rounded_schedule[i] = {}
          @rounded_schedule[i][:interest_payable] = (i <= @reducing_schedule.count ? @reducing_schedule[i][:interest_payable] : 0).round(2)
          @rounded_schedule[i][:principal_payable] = [actual_payment - @rounded_schedule[i][:interest_payable], balance].min
          balance -= @rounded_schedule[i][:principal_payable]
          i += 1
          done = true if balance == 0 
        end
        return @rounded_schedule
      end

    end

  end
end
