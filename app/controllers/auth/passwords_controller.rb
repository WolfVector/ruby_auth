#Clase para resetear el password
module Auth
	class PasswordsController < ApplicationController
		#include UserConcern

		before_action :redirect_if_authenticated

		#Simplemente imprime el view para solicitar el email
		def new

		end

		#Recibe el form de "new"
		def create
			authcon_reset_password User, new_confirmation_path
		end

		#Form a mostrar cuando el usuario ha clic en el enlace que recibió en el correo
		def edit
			authcon_req_new_password User, new_confirmation_path
		end

		#Recibe el form de "edit"
		def update 
			authcon_update_password User, new_confirmation_path
		end

		private

		def password_params
			params.require(:user).permit(:password, :password_confirmation)
		end
	end

end