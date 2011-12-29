module Merb
  module PortfoliosHelper
    def model_names
      [Region, Area, Branch, Center, ClientGroup, Client, Funder, FundingLine, Loan].map{|d| 
        [d.to_s.snake_case.to_sym, d.to_s]
      }.sort_by{|x| x[1]} 
    end
    
    def get_path(arr, from, to)
      arr[arr.index(from)..arr.index(to)-1]
    end

    def constants_to_strings(arr)
      arr.collect{|x| x.to_s.snake_case}
    end
    
    def transform_raw_post_to_hidden_fields(data)
      CGI.unescape(data).split('&').collect{|x| x.split('=')}.reject{|x| x[0]=='submit'}.map{|x| "<input type='hidden' name='#{x[0]}' value='#{x[1]}'>"}.join
    end

  end
end # Merb
