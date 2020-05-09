class CalendarAssistant
  class Config
    class TokenStore
      attr_reader :config

      def initialize(config, key: :tokens)
        @config = config
        @key = key
      end

      def delete(id)
        config.send(@key).delete(id)
        config.persist!
      end

      def load(id)
        config.send(@key)[id]
      end

      def store(id, token)
        config.send(@key)[id] = token
        config.persist!
      end
    end
  end
end
