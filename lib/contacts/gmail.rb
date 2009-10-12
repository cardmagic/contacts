class Contacts
  class Gmail < Base
    
    CONTACTS_SCOPE = 'http://www.google.com/m8/feeds/'
    CONTACTS_FEED = CONTACTS_SCOPE + 'contacts/default/full/'
    
    def contacts
      return @contacts if @contacts
      real_connect
    end
    
    def real_connect
      @client = GData::Client::Contacts.new
      @client.clientlogin(@login, @password)
      
      feed = @client.get(CONTACTS_FEED).to_xml
      
      @contacts = []
      feed.elements.each('entry') do |entry|
        title = entry.elements['title'].text
        email = nil
        entry.elements.each('gd:email') do |e|
          if e.attribute('primary')
            email = e.attribute('address').value
          end
        end
        @contacts << [title, email] unless email.nil?
      end
      @contacts
    end
    
  end
end