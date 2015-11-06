require 'rails_helper'

RSpec.describe Api::StudentsController, type: :controller do


	describe "GET #show" do
		before(:each) do
			@user = FactoryGirl.create :student
			get :show, id: @user.id, foramt: :json
		end


		it "returns email" do
			user_response = JSON.parse(response.body, symbolize_names: true)
			expect(user_response[:email]).to eql @user.email
		end


		it "status = 200" do
			expect(response.status).to eql 200
		end
	end





	describe "POST #create" do
		context "successful" do
			before(:each) do
				@user_attributes = FactoryGirl.attributes_for :student
				post :create, { student: @user_attributes }, format: :json
			end

			it "returns email" do
				user_response = JSON.parse(response.body, symbolize_names: true)
				expect(user_response[:email]).to eql @user_attributes[:email]
      		end


      		it "status = 201" do
				expect(response.status).to eql 201
			end
		end


		context "unsuccessful" do
			before(:each) do
        		@invalid_user_attributes = { password: "12345678", password_confirmation: "12345678" }
        		post :create, { student: @invalid_user_attributes }, format: :json
      		end

		    it "renders an errors json" do
		        user_response = JSON.parse(response.body, symbolize_names: true)
		        expect(user_response).to have_key(:errors)
		    end

		    it "renders error message" do
		        user_response = JSON.parse(response.body, symbolize_names: true)
		        expect(user_response[:errors][:email]).to include "can't be blank"
		    end

		    it "status = 422" do
				expect(response.status).to eql 422
			end
		end
	end


	describe "PUT#update" do
		context "successful update" do
			before(:each) do
				@user = FactoryGirl.create :student
				request.headers['Authorization'] =  @user.auth_token
				put :update, { id: @user.id, student: { password: "password2", password_confirmation: "password2" }}, format: :json
			end

			it "status = 200" do
				expect(response.status).to eql 200
			end
		end
	end


	describe "DELETE #destroy" do
		before(:each) do
			@user = FactoryGirl.create :student
			request.headers['Authorization'] =  @user.auth_token
			delete :destroy, { id: @user.id }, format: :json
		end

		it "status = 204" do
			expect(response.status).to eql 204
		end 

	end
end