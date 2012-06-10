require "rubygems"

if (local_gem_dir = File.join(File.dirname(__FILE__), '..', '..', 'gems')) && $BUNDLE.nil?
  $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(local_gem_dir)
end

namespace :mostfit do
  namespace :books do

    task :setup_accounting do |t, args|
      USAGE = "USAGE: [bin/]rake mostfit:books:setup_accounting"
      begin
        #Setup money categories
        MoneyCategory.create_default_money_categories

        #Setup ledger classifications
        LedgerClassification.create_default_ledger_classifications

        #Setup cost centers
        CostCenter.setup_cost_centers

        #Setup chart of accounts
        coa_file_name = File.join(Merb.root, 'config', 'accounts.yml')
        chart_of_accounts = File.read(coa_file_name)
        accounts = YAML.load(chart_of_accounts)
        Ledger.load_accounts_chart(accounts)

        #Setup account groups
        groups_file_name = File.join(Merb.root, 'config', 'account_groups.yml')
        groups_file = File.read(groups_file_name)
        groups_hash = YAML.load(groups_file)
        AccountGroup.load_accounts_groups(groups_hash)

        #Setup accounting rules
        rules_file_name = File.join(Merb.root, 'config', 'accounting_rules.yml')
        rules_file = File.read(rules_file_name)
        rules = YAML.load(rules_file)
        AccountingRule.load_accounting_rules(rules)

        #Setup product accounting rules
        product_accounting_rules_file_name = File.join(Merb.root, 'config', 'product_accounting_rules.yml')
        product_accounting_rules_file = File.read(product_accounting_rules_file_name)
        product_accounting_rules = YAML.load(product_accounting_rules_file)
        ProductAccountingRule.load_product_accounting_rules(product_accounting_rules)

      rescue => ex
        puts ex.message
        puts USAGE
      end
    end

    task :record_cash_summaries, :for_date do |t, args|
      USAGE = "USAGE: [bin/]rake mostfit:books:record_cash_summaries[<'yyyy-mm-dd'>]"
      begin
        for_date_string = args[:for_date]
        raise ArgumentError, "a valid date was not supplied: #{for_date_string}" unless (for_date_string) and Date.parse(for_date_string)
        for_date = Date.parse(for_date_string)
        summaries = TransactionSummary.generate_disbursements_and_receipts_summary_info(for_date)
        summaries.each { |summary|
          TransactionSummary.record_summary_from_info(summary)
        }
      rescue => ex
        puts ex.message
        puts USAGE
      end
    end

    task :record_regular_interest_accruals, :for_date do |t, args|
      USAGE = "USAGE: [bin/]rake mostfit:books:record_regular_accrual_summaries[<'yyyy-mm-dd'>]"
      begin
        for_date_string = args[:for_date]
        raise ArgumentError, "a valid date was not supplied: #{args[:for_date]}" unless (for_date_string and Date.parse(for_date_string))
        for_date = Date.parse(for_date_string)
        summaries = TransactionSummary.generate_accrual_summary_info(for_date)
        summaries.each { |summary|
          TransactionSummary.record_summary_from_info(summary)
        }
      rescue => ex
        puts ex.to_s
        puts USAGE
      end
    end

    task :record_vouchers, :for_date do |t, args|
      USAGE = "USAGE: [bin/]rake mostfit:books:record_vouchers[<'yyyy-mm-dd'>]"
      begin
        for_date_string = args[:for_date]
        raise ArgumentError, "a valid date was not supplied: #{args[:for_date]}" unless (for_date_string and Date.parse(for_date_string))
        for_date = Date.parse(for_date_string)
        all_summaries_for_date = TransactionSummary.to_be_processed(:effective_on => for_date)
        return unless (all_summaries_for_date and (!all_summaries_for_date.empty?))
        book_keeper = MyBookKeeper.new
        all_summaries_for_date.each { |summary|
          book_keeper.record_voucher(summary)
          summary.set_processed
        }
      rescue => ex
        puts ex.to_s 
        puts USAGE
      end
    end

  end
end