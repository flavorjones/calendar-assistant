#
# code in this file is inspired by
#
#   https://github.com/gsuitedevs/ruby-samples/blob/master/calendar/quickstart/quickstart.rb
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'rainbow'

class CalendarAssistant
  class Authorizer
    class NoCredentials < CalendarAssistant::BaseException ; end
    class UnauthorizedError < CalendarAssistant::BaseException ; end

    OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
    APPLICATION_NAME = "Flavorjones Calendar Assistant".freeze
    CREDENTIALS_PATH = 'credentials.json'.freeze
    TOKEN_PATH = 'token.yaml'.freeze
    SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

    attr_reader :profile_name

    def initialize profile_name
      @profile_name = profile_name
    end

    def authorize
      credentials || prompt_user_for_authorization
    end

    def service
      if credentials.nil?
        raise UnauthorizedError, "Not authorized. Please run `calendar-assistant authorize #{profile_name}`"
      end

      Google::Apis::CalendarV3::CalendarService.new.tap do |service|
        service.client_options.application_name = APPLICATION_NAME
        service.authorization = credentials
      end
    end

  private

    def credentials
      @credentials ||= authorizer.get_credentials profile_name
    end

    def prompt_user_for_authorization
      url = authorizer.get_authorization_url(base_url: OOB_URI)

      puts Rainbow("Please open this URL in your browser:").bold
      puts
      puts "  " + url
      puts

      puts Rainbow("Then authorize '#{APPLICATION_NAME}' to manage your calendar and copy/paste the resulting code here:").bold
      puts
      print "> "
      code = STDIN.gets

      authorizer.get_and_store_credentials_from_code(user_id: profile_name, code: code, base_url: OOB_URI)
    end

    def authorizer
      @authorizer ||= begin
                        if ! File.exists?(CREDENTIALS_PATH)
                          raise NoCredentials, "No credentials found. Please run `calendar-assistant help authorize` for help"
                        end

                        client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
                        token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
                        Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
                      end
    end
  end
end
