module Handlers
  class BaseHandler
    def call(delivery)
      raise NotImplementedError, "#{self.class}#call must be implemented"
    end
  end
end
