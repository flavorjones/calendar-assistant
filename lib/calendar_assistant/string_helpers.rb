class CalendarAssistant
  module StringHelpers
    def self.find_uri_for_domain(string, domain)
      return unless string
      URI::Parser.new.extract(string).each do |uri_string|
        uri = URI.parse uri_string
        return uri_string if uri.hostname =~ /\.#{domain}$/
      end
      nil
    end
  end
end
