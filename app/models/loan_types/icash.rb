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
      
      def self.extended(base)
        base.model.class_eval do 
          # The Dairy Loan is a custom principal and interest loan with some tweaks.
          alias :aps :actual_payment_schedule
          alias :idates  :installment_dates
          base.extend CustomPrincipalAndInterest 
        end
      end

      def self.display_name
        "Dairy Loan with Attached Insurance product"
      end
      
      def installment_dates
        return @_installment_dates if @_installment_dates
        idates
        #to check whether the last payment day is sunday or not. Done on Intellecash request.
        scheduled_last_payment_date = ((disbursal_date || scheduled_disbursal_date) >> 24) + 1
        scheduled_last_payment_date += 1 if (scheduled_last_payment_date.weekday == :sunday)
        @_installment_dates[-1] = scheduled_last_payment_date
        return @_installment_dates
      end

      def actual_payment_schedule
        return @adjusted_schedule if @adjusted_schedule
        aps
        # add the insurance premium to the balance for dates of the 26th installment onwards 
        @premium ||= (insurance_policy or Nothing).premium || 0
        @adjusted_schedule = @schedule.map{|date, row|
          # $debug = true if row[:installment_number] >= 26 if $debug.nil?
          # debugger if $debug
          [date, row.merge(:balance => row[:balance] + (row[:installment_number] >= 26 ? @premium : 0))]
        }.to_hash
        return @adjusted_schedule
      end
    end  # Dairy Loan

  end
end

