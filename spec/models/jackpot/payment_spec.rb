require 'spec_helper'

module Jackpot 
  describe Payment , :vcr do
    it { should belong_to :customer } 
    it { should belong_to :subscription } 

    let(:fail_response)     { stub("success?" => false) } 

    let(:subscription)      { Factory(:subscription, :price => 4200) } 
    let(:customer)          { Factory(:customer_with_valid_card, :email => 'john@doe.com') } 

    let(:invalid_customer)  { Factory(:customer, :email => 'john@doe.com',
                                      :credit_card_token => '1') } 

    let(:payment)         { Payment.create(:description => "foo", 
                           :customer     => customer, 
                           :subscription => subscription) }

    let(:invalid_payment) { Payment.create(:description => "foo", 
                             :customer     => invalid_customer, 
                             :subscription => subscription) }


    describe ".customer_name"  do
      it "returns its customer email" do
        payment.customer_email.should == "john@doe.com"
      end 
    end 

    describe "#create" do
      context "with valid token information"  do 
        let(:retrieved_payment) { Payment.find(payment.id) } 

        it "creates a new payment" do
          expect { payment }.to change(Payment, :count).by(1)
        end 

        it "records the payment transaction id for future reference" do
          retrieved_payment.payment_transaction_token.should == "1561142493"
        end 

        it "records this payment information" do
          retrieved_payment.amount.should          == 42
          retrieved_payment.description.should_not be_nil 
          retrieved_payment.subscription.should_not be_nil 
        end 

        it "does not persist credit card token information" do
          retrieved_payment.credit_card_token.should be_nil
        end 
      end 
      context "with invalid token information"  do
        before do
          Jackpot::Gateway.any_instance.stub(:authorize)
                                  .with(42, '1')
                                  .and_return(fail_response)
        end 

        it "raises an unauthorized token information" do
          expect { invalid_payment }.to raise_error Jackpot::Errors::UnauthorizedPayment
        end

        it "must not save an additional payment" do
          begin
            invalid_payment
          rescue Jackpot::Errors::UnauthorizedPayment
            Payment.count.should == 0
          end 
        end 
      end 
    end 
  end
end 
