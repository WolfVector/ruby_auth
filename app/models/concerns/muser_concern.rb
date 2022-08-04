module MuserConcern
	#Ejecuta cuando el user haya confirmado su email
    def confirm!
      if unconfirmed_or_reconfirming? #Si email aún no está confirmado o si uncofirmed_email aún no está confirmado 
        if unconfirmed_email.present? #Si unconfirmed_email existe, entonces actualiza email
          return false unless update(email: unconfirmed_email, unconfirmed_email: nil)
        end
        update_columns(confirmed_at: Time.current) #Valida la actualización
      else
        false
      end
    end

    #Función para verificar si el email ha sido confirmado
    def confirmed?
      confirmed_at.present?
    end

    #Función que retorna el current email
    def confirmable_email
      if unconfirmed_email.present?
        unconfirmed_email
      else
        email
      end
    end

    #Función que verifica si estamos actualizando el email
    def reconfirming?
      unconfirmed_email.present?
    end

    #Nuevo email o actualizando email
    def unconfirmed_or_reconfirming?
      unconfirmed? || reconfirming?
    end

    #Función para crear el token
    #signed_id es asociado con el email por un tiempo de 10min
    #Después de ese límite de tiempo no será posible recuperar el user con dicho token
    def generate_confirmation_token(token_expiration)
      signed_id expires_in: token_expiration, purpose: :confirm_email
    end

    #Función para verificar si el email no ha sido confirmado
    def unconfirmed?
      !confirmed?
    end

    #Enviar la confirmación
    def send_confirmation_email!(token_expiration)
      confirmation_token = generate_confirmation_token token_expiration
      #Envía la confirmación
      Auth::UserMailer.confirmation(self, confirmation_token).deliver_now
    end

    #Función para generar el token para el reset
    def generate_password_reset_token(token_expiration)
      signed_id expires_in: token_expiration, purpose: :reset_password
    end

    #Función que genera el token y lo envía en un correo para resetear el password
    def send_password_reset_email!(token_expiration)
      password_reset_token = generate_password_reset_token token_expiration
      Auth::UserMailer.password_reset(self, password_reset_token).deliver_now
    end
end