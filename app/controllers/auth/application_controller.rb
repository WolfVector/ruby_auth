module Auth
  class ApplicationController < ActionController::Base
    layout 'application'
    include Authentication, UserConcern

    def login(user)
      reset_session #Evitamos session fixation
      session[:current_user_id] = user.id #Almacenamos el user id en el session storage
    end
  
    def current_user
      Current.user ||= if session[:current_user_id].present? 
        User.find_by(id: session[:current_user_id])
      elsif cookies.permanent.encrypted[:remember_token].present?
        User.find_by(remember_token: cookies.permanent.encrypted[:remember_token])
      end
    end

    #def authenticate_user!
    # store_location #Guarda la url protegida que el user intentó acceder
      #Redirecciona a login page
    #  redirect_to login_path, alert: "Yo need to login to access that page" unless user_signed_in?
    #end

  end
end
