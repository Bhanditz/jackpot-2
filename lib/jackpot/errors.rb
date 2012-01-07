module Jackpot

  module Errors
    ## 
    ## This error is raised when Jackpot::Payment.initialize_credit_card tries to
    ## issue a payment to an invalid card 
    #
    CardIsInvalid = Class.new(StandardError)
  end 
    
end 