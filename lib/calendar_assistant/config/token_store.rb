class CalendarAssistant
  class Config
    class TokenStore
      attr_reader :config

      def initialize config
        @config = config
      end

      def delete id
        config[CalendarAssistant::Config::Keys::TOKENS].delete(id)
        config.persist!
      end

      def load id
        config[CalendarAssistant::Config::Keys::TOKENS][id]
      end

      def store id, token
        config[CalendarAssistant::Config::Keys::TOKENS][id] = token
        config.persist!
      end
    end
  end
end
