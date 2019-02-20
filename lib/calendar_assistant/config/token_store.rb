class CalendarAssistant
  class Config
    class TokenStore
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def delete(id)
        config.tokens.delete(id)
        config.persist!
      end

      def load(id)
        config.tokens[id]
      end

      def store(id, token)
        config.tokens[id] = token
        config.persist!
      end
    end
  end
end
