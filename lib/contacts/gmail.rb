require 'gdata'
require 'nokogiri'

class Contacts
  class Gmail < Base

    CONTACTS_SCOPE = 'http://www.google.com/m8/feeds/'
    CONTACTS_FEED = CONTACTS_SCOPE + 'contacts/default/full/?max-results=1000'

    def contacts
      return @contacts if @contacts
    end

    def real_connect
      @client = GData::Client::Contacts.new
      @client.clientlogin(@login, @password, @captcha_token, @captcha_response)

      feed = Nokogiri::XML(@client.get(CONTACTS_FEED).body)

      @contacts = feed.root.elements.select {|n| n.name == 'entry' }.map do |node|
        children = node.children
        email = children.last.attr('address')

        if email.nil? || email.empty?
          nil
        else
          name = children.search('title').text
          name = guess_name(email) if name.nil? || name.empty?
          [name, email]
        end
      end.compact
    rescue GData::Client::AuthorizationError => e
      raise AuthenticationError, "Username or password are incorrect"
    end

    private

    TYPES[:gmail] = Gmail
  end
end