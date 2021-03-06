class Api::SessionsController < ApplicationController
	
	def create
		user_password = params[:session][:password]
		user_email = params[:session][:email]
		user_is_trainer = params[:session][:is_trainer]

		user = nil
		if user_is_trainer == '1'
			user = user_email.present? && Trainer.find_by(email: user_email)
		elsif user_is_trainer == '0'
			user = user_email.present? && Student.find_by(email: user_email)
		else
			render json: { errors: ["invalid is_trainer value"] }, status: 422
			return
		end

		
		if user.nil?
			render json: { errors: ["Invalid email"] }, status: 422

		elsif !user.confirmed
			render json: { errors: ["Emails needs to be verified"] }, status: 422

		elsif user.valid_password? user_password
			sign_in user, store: false
			user.generate_authentication_token!
			user.save
			render json: { username: user.username, auth_token: user.auth_token }, status: 200, location: [:api, user]

		else
			render json: { errors: ["Invalid password"] }, status: 422
		end

	end




	def destroy
		user = Trainer.find_by(auth_token: params[:id])
		if user.nil?
			user = Student.find_by(auth_token: params[:id])
		end

		if user.nil?
			render json: { errors: ['Not authenticated'] }, status: 401
		else
			user.generate_authentication_token!
			user.save
			head 204
		end
	end


end
