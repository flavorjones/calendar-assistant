#
# code in this file is borrowed from
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

class CalendarAssistant
  module Authorizer
    OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
    APPLICATION_NAME = "Flavorjones Calendar Assistant".freeze
    CREDENTIALS_PATH = 'credentials.json'.freeze
    TOKEN_PATH = 'token.yaml'.freeze
    SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY

    def self.authorize profile_name
      auth_impl profile_name, true
    end

    def self.service profile_name
      auth_impl profile_name, false
    end

    private

    def self.auth_impl profile_name, create_profile_p
      service = Google::Apis::CalendarV3::CalendarService.new
      service.client_options.application_name = APPLICATION_NAME

      client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      credentials = authorizer.get_credentials profile_name

      if credentials.nil?
        raise "Not authorized. Please run `calendar-assistant authorize #{profile_name}`" unless create_profile_p

        url = authorizer.get_authorization_url(base_url: OOB_URI)
        puts "Open the following URL in the browser and enter the resulting code after authorization:"
        puts
        puts url
        puts
        code = STDIN.gets
        credentials = authorizer.get_and_store_credentials_from_code(user_id: profile_name, code: code, base_url: OOB_URI)
      end

      service.authorization = credentials
      service
    end
  end
end
