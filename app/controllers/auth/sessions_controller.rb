#Clase para manejar el login
module Auth
	class SessionsController < ApplicationController
		#include UserConcern

		#Si ya estás autenticado, entonces no puedes acceder al login page
		before_action :redirect_if_authenticated, only: [:create, :new]

		#Sólo puedes acceder a esta url si has iniciado sesión
		before_action :authenticate_user!, only: [:destroy] 

		#No retornamos un user model, simplemente imprime el view
		def new

		end

		#Post para el login
		def create
			authcon_login User, new_confirmation_path
		end


		def destroy
			forget(current_user)

			logout
			redirect_to login_path, notice: "Signed out"
		end
	end
end