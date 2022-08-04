#ActiveSupport::CurrentAttributes permite crear un módulo en un thread global aislado,
#de tal forma que sus atributos sólo serán visibles para el current request
module Auth
	class Current < ActiveSupport::CurrentAttributes
		attribute :user
	end
end