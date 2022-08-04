#Clase para registrar un nuevo usuario, editarlo y destruirlo
module Auth
	class UsersController < ApplicationController
		#include UserConcern

		#Si el usuario ya inició sesión, entonces no permitas que entre a 'create' y ¿new
		before_action :redirect_if_authenticated, only: [:create, :new]

		#Si el usuario no ha iniciado sesión, no permitas que entre a 'edit', 'destroy' y 'update'
		before_action :authenticate_user!, only: [:edit, :destroy, :update]

		#get: Retorna el modelo para construir el form (registrar user)
		def new
			@user = User.new 
		end

		#post: instancia un nuevo modelo y si no hay errores en las validaciones entonces almacena los datos
		#Crear user
		def create
			#authcon_new_user User, create_user_params
			if authcon_new_user(:user_class => User, :required_params => create_user_params)
				flash[:notice] = "Please check your email for confirmation instructions."
			end
		end

		#Función para destruir la cuenta
		def destroy
			current_user.destroy
			reset_session
			redirect_to login_path, notice: "Your account has been deleted"
		end

		#Despliega un form para editar la cuenta del usuario
		def edit
			@user = current_user
		end

		#Recibe el form proveniente de 'edit' y actuliza los campos
		def update
			@user = current_user
			if authcon_update_user(:user_class => @user, :required_params => update_user_params)
				if params[:user][:unconfirmed_email].present?
					msg = "Check your email for confirmation instructions"
				else
					msg = "Account updated"
				end

				flash[:notice] = msg
			end
		end

		private

		def create_user_params
			params.require(:user).permit(:email, :password, :password_confirmation)
		end

		def update_user_params
			params.require(:user).permit(:current_password, :password, :password_confirmation, :unconfirmed_email)
		end
	end
end