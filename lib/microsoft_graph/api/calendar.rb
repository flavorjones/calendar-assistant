module MicrosoftGraph
  module API
    class Calendar
      def find_events(access_token)
        uri = URI('https://graph.microsoft.com/v1.0/me/calendarview?startdatetime=2020-05-25T00:00:01.978Z&enddatetime=2020-05-25T23:59:50.978Z')
        req = Net::HTTP::Get.new(uri)
        req['Authorization'] = "Bearer #{access_token}"

        res = Net::HTTP.start(uri.hostname, uri.port) {|http|
          http.request(req)
        }

        puts res.code
        puts res.body
      end
    end
  end
end
