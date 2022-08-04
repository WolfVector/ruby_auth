module UserConcern
	CONFIRMATION_TOKEN_EXPIRATION = 10.minutes
    PASSWORD_RESET_TOKEN_EXPIRATION = 10.minutes
	#Buscamos hacer independency injection para utilizar estos métodos con cualquier modelo
	
	#Creamos usuario y enviamos correo de confirmación
	#def authcon_new_user(user_class, required_params, token_exp = nil, msg = nil)
	def authcon_new_user(options)
		authcon_get_default(options, CONFIRMATION_TOKEN_EXPIRATION)

		@user = options[:user_class].new(options[:required_params])
		if @user.save
			@user.send_confirmation_email! options[:token_exp]
			redirect_to options[:redirect_path]
			true
		else
			render :new, status: :unprocessable_entity		
			false
		end
	end

	#Update user
	#def authcon_update_user(user_class, required_params, token_exp = nil)
	def authcon_update_user(options)
		authcon_get_default(options, CONFIRMATION_TOKEN_EXPIRATION)

		if options[:user_class].authenticate(params[:user][:current_password]) #Si la contraseña es correcta, entonces procede con la actulización
			if options[:user_class].update(options[:required_params]) #Si no hubo error en la actulización...
				if params[:user][:unconfirmed_email].present? #Si el campo para nuevo email no está vacío, entonces envía un correo de confirmación
					options[:user_class].send_confirmation_email! options[:token_expiration]
					redirect_to options[:redirect_path]
				else #En caso contrario simplemente actuliza los otros campos
					redirect_to options[:redirect_path]
				end

				true
			else
				render :edit, status: :unprocessable_entity
				false
			end
		else
			flash.now[:error] = "Incorrect password"
			render :edit, status: :unprocessable_entity
			false
		end
	end

	def authcon_direct_update_user(options)
		authcon_get_default(options, CONFIRMATION_TOKEN_EXPIRATION)

		if options[:user_class].update(options[:required_params])
			options[:user_class].send_confirmation_email! options[:token_exp]
			redirect_to options[:redirect_path]

			true
		else
			false
		end		
	end
	#Reenviar correo de confirmación
	def authcon_send_confirmation(user_class, token_exp = nil)
		token_expiration = CONFIRMATION_TOKEN_EXPIRATION if token_exp.nil?
		@user = user_class.find_by(email: params[:user][:email].downcase)

		#Si existe y el usuario aún está sin confirmar, entonces reenvía
		if @user.present? && @user.unconfirmed?
			@user.send_confirmation_email! token_expiration
			redirect_to Auth::Engine.routes.url_helpers.root_path, notice: "Check your email for confirmation instructions"
		else
			redirect_to new_confirmation_path, alert: "We could not find a user with that email or that email has already been confirmed."
		end
	end

	#Recibe la confirmación y guárdala
	def authcon_save_confirmation(user_class, redirect_path)
		#Retorna el usuario asociado con el token y el purpose
		@user = user_class.find_signed(params[:confirmation_token], purpose: :confirm_email)

		#Si existe dicho usuario, entonces confirma el registro
		#Sólo usuarios que están confirmado su registro o actulizando su email pueden realizar esta operación
		if @user.present? && @user.unconfirmed_or_reconfirming?
			if @user.confirm! #confirma el registro
				login @user    #Inicia sesión
				redirect_to Auth::Engine.routes.url_helpers.root_path, notice: "Your account has been confirmed"
			else
				redirect_to redirect_path, alert: "Something went wrong"
			end
		else
			redirect_to redirect_path, alert: "Invalid token"
		end
	end

	#Login user
	def authcon_login(user_class, redirect_path, msg = '')
		@user = user_class.find_by(email: params[:user][:email].downcase)
		msg = "Revisa tu correo para confirmar tu registro" if msg.empty?
		
		#Si el usuario existe
		if @user
			if @user.unconfirmed? #Si el usuario aún no ha confirmado su registro
				redirect_to redirect_path, alert: msg
			elsif @user.authenticate(params[:user][:password]) #Si el usuario ya confirmó su registro
				after_login_path = session[:user_return_to] || '/auth'
				login @user #Login

				#Recuerda el user si seleccionó dicha opción
				remember(@user) if params[:user][:remember_me] == "1"
				redirect_to after_login_path
				#{:user => user, :status => true}
			else
				false
				#flash.now[:alert] = "Email o password incorrecto"
				#render "auth/sessions/new", status: :unprocessable_entity
				#{:status => false, :user => user}
			end	
		else
			false
			#flash.now[:alert] = "Email o password incorrecto"
			#render "auth/sessions/new", status: :unprocessable_entity
			#{:status => false, :user => user}
		end
	end

	#Usuario olvidó password, envía correo para reiniciarlo
	def authcon_reset_password(user_class, redirect_path, token_exp = nil)
		token_expiration = PASSWORD_RESET_TOKEN_EXPIRATION if token_exp.nil?
		@user = user_class.find_by(email: params[:user][:email].downcase)
			
		#Si el usuario existe
		if @user.present?
			if @user.confirmed? #Si el usuario ya confirmó su registro
				@user.send_password_reset_email! token_expiration #Envía los pasaos para resetear el password
				redirect_to Auth::Engine.routes.url_helpers.root_path, notice: "If that user exists we've sent instructions to his email"
			else
				redirect_to redirect_path, alert: "Please confirm your email first"
			end
		else
			redirect_to Auth::Engine.routes.url_helpers.root_path, notice: "User does not exists"
		end
	end

	#Recibe el token y solicita nuevo password
	def authcon_req_new_password(user_class, redirect_path)
		@user = user_class.find_signed(params[:password_reset_token], purpose: :reset_password)

		#Si el usuario existe pero aún no confirm su email
		if @user.present? && @user.unconfirmed?
			redirect_to redirect_path, alert: "You must confirm your email before you can sign in"
		elsif @user.nil?  #Si el usuario no existe
			redirect_to redirect_path, alert: "Invalid or expired token"
		end
	end

	#Actualiza el password
	def authcon_update_password(user_class, redirect_path)
		@user = user_class.find_signed(params[:password_reset_token], purpose: :reset_password)

		#Si el usuario existe
		if @user
			if @user.unconfirmed? #Si el usuario aún no confirmado su registro
				redirect_to redirect_path, alert: "You must confirm your email before you can sign in"
			elsif @user.update(password_params) #Si ya lo confirmó, entonces guarda las nuevas contraseñas
				redirect_to login_path, notice: "Sign in" 
			else
				flash.now[:alert] = @user.errors.full_messages.to_sentence
				render :edit, status: :unprocessable_entity
			end
		else
			flash.now[:alert] = "Invalid or expired token"
			render :new, status: :unprocessable_entity
		end
	end

	private
		def authcon_get_default(options, token_exp)
			if !options.has_key?(:redirect_path)
				options[:redirect_path] = Auth::Engine.routes.url_helpers.login_path
			end		

			if !options.has_key?(:token_exp)
				options[:token_exp] = token_exp
			end
		end

end