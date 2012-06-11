class ChequeLeaf
  include DataMapper::Resource

  property :id, Serial
  property :serial_no, Integer, :nullable=>false, :min=>100000,:max=>999999
  property :deleted, Boolean,:default=>false
  property :created_at, DateTime
  property :deleted_at, DateTime
  property :created_by_user_id, Integer, :nullable=>false
  property :deleted_by_user_id, Integer
  property :used,Boolean,:default=>false
  property :valid, Boolean,:default=>true


  belongs_to :bank_account

  def self.generate_data
    3.times do |i|
      @bank = Bank.create!(:name=>"Bank#{i+1}", :created_at=>Time.now, :created_by_user_id=>1)
      3.times do |j|
        @bank_branch = BankBranch.create!(:name=>"Bank#{i+1} Branch#{j+1}", :created_at=>Time.now, :created_by_user_id=>1,:bank_id=>@bank.id)
        3.times do |k|
          @bank_account = BankAccount.create!(:name=>"Bank#{i+1} Branch#{j+1} Account#{k+1}", :created_at=>Time.now, :account_no=>"ACC#{i+1}#{j+1}#{k+1}", BankBranch.created_at=>Time.now, :created_by_user_id=>1,:bank_branch_id=>@bank_branch.id)
        end
      end
    end

  end



end
