#El módulo será incluido en ApplicationController, de está forma todos los controladores tendrán acceso a él
module Authentication
	extend ActiveSupport::Concern

	#El código incluido en este bloque será integrado como si perteneciera a ApplicationController
	#El código fuera de esta bloque será integrado en el 'ancestors'.
	included do
		before_action :current_user #Ejecuta la función antes de manejar el request
		helper_method :current_user #Con el helper podremos acceder a la función desde los views
		helper_method :user_signed_in?
	end

	#@_login_path = Auth::Engine.routes.url_helpers.login_path
	#@_root_path = Auth::Engine.routes.url_helpers.root_path

	#Login
	def login(user)
		reset_session #Evitamos session fixation
		session[:current_user_id] = user.id #Almacenamos el user id en el session storage
	end

	#Cerramos sesión
	def logout
		reset_session
	end

	#Olvida la sesión
	def forget(user)
		cookies.delete :remember_token #Elimina la cookie "permanente"
		user.regenerate_remember_token #Regenerá el token para que el anterior ya no se pueda usar
	end

	#Recuerda la sesión
	def remember(user)
		user.regenerate_remember_token #Generá un nuevo token
		#Guarda el token en una cookie "permanente" (20 años) y encriptada
		cookies.permanent.encrypted[:remember_token] = user.remember_token
	end

	#Si el usuario ya está autenticado, entonces redirecciónalo
	def redirect_if_authenticated
		redirect_to Auth::Engine.routes.url_helpers.root_path, alert: "You are already logged in." if user_signed_in?
	end

	def authenticate_user!
		store_location #Guarda la url protegida que el user intentó acceder
		#Redirecciona a login page
		redirect_to login_path, alert: "Yo need to login to access that page" unless user_signed_in?
	end

	private 

	#Obtenemos el usuario que está haciendo el request y lo almacenamos en su thread
	def current_user
		#user_model = Auth::User if user_class.nil?

		#Obtén el usuario a través de la sesión o el token de recuerdame
		Auth::Current.user ||= if session[:current_user_id].present? 
			User.find_by(id: session[:current_user_id])
		elsif cookies.permanent.encrypted[:remember_token].present?
			User.find_by(remember_token: cookies.permanent.encrypted[:remember_token])
		end
	end

	#Para verificar si el usuario ha sido almacenado en su thread
	def user_signed_in?
		Auth::Current.user.present?
	end

	#Guarda la url
	def store_location
		#Guarda la url si esta provinó de un petición get y la url es local
		session[:user_return_to] = request.original_url if request.get? && request.local?
	end
end