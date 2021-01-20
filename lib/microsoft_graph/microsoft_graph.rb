class MicrosoftGraph
  def initialize(access_token, refresh_token)
    @access_token = access_token
    @refresh_token = refresh_token
  end


  def get_calendar(id=nil)
    response = fetch('https://graph.microsoft.com/v1.0/me/calendars')
    response['value'].first
  end

  private

  def fetch(url)
    uri = URI(url)

    headers  = {"Authorization" => "Bearer #{@access_token}"}
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    res = http.get(uri.request_uri, headers)

    JSON.parse(res.body)
  end
end
