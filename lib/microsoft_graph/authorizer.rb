class MicrosoftGraph
  class Authorizer
    class AuthorizationError; end
    class GrantTypes
      DEVICE_CODE = "urn:ietf:params:oauth:grant-type:device_code".freeze
      REFRESH_TOKEN = "refresh_token".freeze
    end

    def self.device_code(tenant_id, client_id, scope)
      uri = URI("https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/devicecode")
      res = Net::HTTP.post_form(uri, {
        "client_id" => client_id,
        "scope" => scope
      })

      json = JSON.parse(res.body)
      interval = json["interval"]
      device_code = json["device_code"]

      puts Rainbow(json["message"]).bold
      Launchy.open("https://microsoft.com/devicelogin")

      10.times do
        sleep(interval)
        uri = URI("https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token")
        res = Net::HTTP.post_form(uri, {
          "client_id" => client_id,
          "grant_type" => GrantTypes::DEVICE_CODE,
          "device_code" => device_code
        })

        return res.body if res.code == "200"
      end

      raise AuthorizationError
    end

    def self.refresh_tokens(tenant_id, client_id, refresh_token)
      uri = URI("https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token")
      res = Net::HTTP.post_form(uri, {
        "client_id" => client_id,
        "grant_type" => GrantTypes::REFRESH_TOKEN,
        "refresh_token" => refresh_token,
      })
      puts res.code
      puts res.body
      return res.body if res.code == "200"
    end
  end
end
