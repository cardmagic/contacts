require 'gdata'

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
        name = children.search('title').text
        email = children.last.attr('address')

        [name, email] unless name.empty? || email.empty?
      end.compact
    rescue GData::Client::AuthorizationError => e
      raise AuthenticationError, "Username or password are incorrect"
    end

    private

    TYPES[:gmail] = Gmail
  end
end