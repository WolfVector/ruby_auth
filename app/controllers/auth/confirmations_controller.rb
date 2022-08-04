#Este controlador maneja dos cosas:
#1. Maneja un new y un create para reenviar el mensaje de confirmación en caso de que sea necesario
#2. El edit se encarga de recibir la confirmación y almacenarla
module Auth
	class ConfirmationsController < ApplicationController
		#include UserConcern

		before_action :redirect_if_authenticated, only: [:create, :new]

		#Retornamos el modelo para crear un form de reenvío
		def new
			@user = User.new
		end

		#Si el email existe, entonces notifica al usuario del reenvío
		def create
			authcon_send_confirmation User
		end

		#Recibe la confirmación
		def edit
			authcon_save_confirmation User, new_confirmation_path
		end
	end
end