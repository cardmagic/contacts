require 'httparty'

class Contacts
  class Basecamp < Base
    ACCOUNT_URL = 'https://%s.basecamphq.com'
    include HTTParty
    attr_reader :contacts

    def real_connect
      @subdomain = ACCOUNT_URL % @login
      # Basecamp basic auth uses "api_token:X" and ignores the password field
      @auth = {:username => @password, :password => 'X'}

      people = self.class.get("#{@subdomain}/people.xml", { :basic_auth => @auth })["people"]

      if people
        @contacts = people.map { |person| [person["first_name"] + ' ' + person["last_name"], person["email_address"]]}
      else
        raise Contacts::AuthenticationError, "Subdomain or API key is incorrect"
      end
    end
  end

  private
  TYPES[:basecamp] = Basecamp
end