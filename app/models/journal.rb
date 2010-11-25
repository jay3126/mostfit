require 'builder'
class Journal
  include DataMapper::Resource
  include DateParser
  
  before :valid?, :parse_dates
 
  property :id,             Serial
  property :comment,        String
  property :transaction_id, String, :index => true  
  property :date,           Date,   :index => true, :default => Date.today
  property :created_at,     DateTime, :index => true  
  property :batch_id,       Integer, :nullable => true
  belongs_to :batch
  belongs_to :journal_type
  has n, :postings
 
  
  def validity_check
    return false if self.postings.length<2 #minimum one posting for credit n one for debit
    debit_account_postings, credit_account_postings = self.postings.group_by{|x| x.amount>0}.values
    return false if debit_account_postings.nil?  or debit_account_postings.length==0
    return false if credit_account_postings.nil? or credit_account_postings.length==0 
    return false if (credit_account_postings.map{|x| x.account_id} & debit_account_postings.map{|x| x.account_id}).length > 0
    return false if self.postings.accounts.map{|x| x.branch_id}.uniq.length > 1
    return true
  end


  def self.create_transaction(journal_params, debit_accounts, credit_accounts)
    # debit and credit accounts can be either hashes or objects
    # In case of hashes, this is the structure
    # debit_accounts =>  {Account.get(1) => 100, Account.get(2) => 30}
    # credit_accounts => {Account.get(3) => 200}
    # Otherwise we have account object as credit_account & debit_account 
    # and we have a amount key in journal_params which has the amount
    
    status = false
    journal = nil

    transaction do |t|
      journal = Journal.create(:comment => journal_params[:comment], :date => journal_params[:date]||Date.today,
                               :transaction_id => journal_params[:transaction_id],
                               :journal_type_id => journal_params[:journal_type_id])
      
      amount = journal_params.key?(:amount) ? journal_params[:amount].to_i : nil

      #debit entries
      if debit_accounts.is_a?(Hash)
        debit_accounts.each{|debit_account, amount|
          Posting.create(:amount => amount * -1, :journal_id => journal.id, :account => debit_account, :currency => journal_params[:currency],:journal_type_id => journal_params[:journal_type_id],:date => journal_params[:date]||Date.today)
        }
      elsif debit_accounts.is_a?(Hash) and amount
        debit_accounts.each{|debit_account, a|          
          Posting.create(:amount => amount * -1, :journal_id => journal.id, :account => debit_account, :currency => journal_params[:currency])
        }        
      else
        Posting.create(:amount => amount * -1, :journal_id => journal.id, :account => debit_accounts, :currency => journal_params[:currency],:journal_type_id => journal_params[:journal_type_id],:date => journal_params[:date]||Date.today)
      end
      
      #credit entries
      if credit_accounts.is_a?(Hash)
        credit_accounts.each{|credit_account, amount|
          Posting.create(:amount => amount, :journal_id => journal.id, :account => credit_account, :currency => journal_params[:currency],:journal_type_id => journal_params[:journal_type_id],:date => journal_params[:date]||Date.today)
        }
      elsif credit_accounts.is_a?(Hash) and amount        
        credit_accounts.each{|credit_account, a|          
          Posting.create(:amount => amount, :journal_id => journal.id, :account => credit_account, :currency => journal_params[:currency])
        } 
      else
        Posting.create(:amount => amount, :journal_id => journal.id, :account => credit_accounts, :currency => journal_params[:currency],:journal_type_id => journal_params[:journal_type_id],:date => journal_params[:date]||Date.today)
      end
      
      # Rollback in case of both accounts being the same      
      if journal.validity_check
        status = true
      else
        t.rollback
        status = false
      end
    end

    return [status, journal]
  end
  
  def self.for_branch(branch, offset=0, limit=25)
    sql  = %Q{
              SELECT j.id, j.comment comment, j.date date, SUM(if(p.amount>0, p.amount, 0)) amount, 
              group_concat(ca.name) credit_accounts, group_concat(da.name) debit_accounts
              FROM journals j, accounts a, postings p
              LEFT OUTER JOIN accounts da ON p.account_id=da.id AND p.amount<0
              LEFT OUTER JOIN accounts ca ON p.account_id=ca.id AND p.amount>0
              WHERE a.branch_id=#{branch.id} AND a.id=p.account_id and p.journal_id=j.id
              GROUP BY j.id
              ORDER BY j.created_at DESC
              OFFSET #{offset}
              LIMIT #{limit}
              }
    repository.adapter.query(sql)
  end
  
# This function will create multiple vouchers 
  def self.xml_tally(hash={})
    xml_file = '/tmp/voucher.xml'
    f = File.open(xml_file,'w')
    x = Builder::XmlMarkup.new(:indent => 1)
    x.ENVELOPE{
      x.HEADER {    
        x.VERSION "1"
        x.TALLYREQUEST "Import"
        x.TYPE "Data"
        x.ID "Vouchers"  
      }
      
      x.BODY { 
        x.DESC{
        }
        x.DATA{
          x.TALLYMESSAGE{
            Journal.all(hash).each do |j|
              debit_posting, credit_posting = j.postings.group_by{ |p| p.amount > 0}.values
              x.VOUCHER{
                x.DATE j.date.strftime("%Y%m%d")
                x.NARRATION j.comment
                x.VOUCHERTYPENAME j.journal_type.name
                x.VOUCHERNUMBER j.id
                credit_posting.each do |p|
                  x.tag! 'ALLLEDGERENTRIES.LIST' do
                    x.LEDGERNAME(p.account.name)
                    x.ISDEEMEDPOSITIVE("No")
                    x.AMOUNT(p.amount)
                  end
                end
                debit_posting.each do |p|
                  x.tag! 'ALLLEDGERENTRIES.LIST' do
                    x.LEDGERNAME(p.account.name)
                    x.ISDEEMEDPOSITIVE("Yes")
                    x.AMOUNT(p.amount)
                  end
                end
              }
            end
          }
        }
      }
    } 
    f.write(x)
    f.close
  end 
#this function will create single voucher 
  def self.voucher(hash={})
    xml_file = '/tmp/single1.xml'
    f = File.open(xml_file,'w')
    x = Builder::XmlMarkup.new(:indent => 1)
    x.ENVELOPE{
      x.HEADER {    
        x.VERSION "1"
        x.TALLYREQUEST "Import"
        x.TYPE "Data"
        x.ID "Vouchers"  
      }
      
      x.BODY { 
        x.DESC{
        }
        x.DATA{
          x.TALLYMESSAGE{           
            credit = Journal.all.postings(hash.merge(:amount.gt => 0)).aggregate(:account_id,:journal_type_id,:amount.sum)
            debit = Journal.all.postings(hash.merge(:amount.lt => 0)).aggregate(:account_id,:journal_type_id,:amount.sum)
            ledger = Account.all
            [1,2].map{|y|
              x.VOUCHER{
                x.DATE Date.today.strftime("%Y%m%d")
                x.NARRATION "#{Date.today}" + " combined journal entry"
                if y==1 
                  name = "Payment" 
                elsif y == 2 
                  name = "Receipt" 
                end
                x.VOUCHERTYPENAME name 
                x.VOUCHERNUMBER Date.today.strftime("%Y%m%d") + " " + name
                credit.each { |c|
                  if c[1] == y
                    x.tag! 'ALLLEDGERENTRIES.LIST' do
                      ledger.each{ |l|
                        if l.id == c[0]
                          x.LEDGERNAME l.name
                        end
                      }
                      x.ISDEEMEDPOSITIVE("No")
                      x.AMOUNT c[2].round(2)
                    end
                  end
                }
                debit.each {|d|
                  if d[1] == y
                    x.tag! 'ALLLEDGERENTRIES.LIST' do
                      ledger.each { |l|
                        if l.id == d[0]
                          x.LEDGERNAME l.name
                        end
                      }
                      x.ISDEEMEDPOSITIVE("Yes")  
                      x.AMOUNT d[2].round(2)
                    end 
                  end
                }
              }
            }
          }
        }
      }
    } 
    f.write(x)
    f.close
  end 
end
