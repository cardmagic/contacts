require 'rexml/document'

class Contacts
  class Plaxo < Base
    URL                 = "http://www.plaxo.com/"
    LOGIN_URL           = "https://www.plaxo.com/signin"
    ADDRESS_BOOK_URL    = "http://www.plaxo.com/po3/?module=ab&operation=viewFull&mode=normal"
    CONTACT_LIST_URL    = "http://www.plaxo.com/axis/soap/contact?_action=getContacts&_format=xml"
    PROTOCOL_ERROR      = "Plaxo has changed its protocols, please upgrade this library first. If that does not work, dive into the code and submit a patch at http://github.com/cardmagic/contacts"
    
    def real_connect
      
    end # real_connect
    
    def contacts
      getdata = "&authInfo.authByEmail.email=%s" % CGI.escape(login)
      getdata += "&authInfo.authByEmail.password=%s" % CGI.escape(password)
      data, resp, cookies, forward = get(CONTACT_LIST_URL + getdata)
      
      if resp.code_type != Net::HTTPOK
        raise ConnectionError, PROTOCOL_ERROR
      end
      
      parse data
    end # contacts
    
  private
    def parse(data, options={})
      doc = REXML::Document.new(data)
      code = doc.elements['//response/code'].text
      
      if code == '401'
        raise AuthenticationError, "Username and password do not match"
      elsif code == '200'
        @contacts = []
        doc.elements.each('//contact') do |cont|
          name = if cont.elements['fullName']
            cont.elements['fullName'].text
          elsif cont.elements['displayName']
            cont.elements['displayName'].text
          end
          email = if cont.elements['email1']
            cont.elements['email1'].text
          end
          if name || email
            @contacts << [name, email]
          end
        end
        @contacts
      else
        raise ConnectionError, PROTOCOL_ERROR
      end
      
    end # parse

  end # Plaxo
  
  TYPES[:plaxo] = Plaxo
  
end # Contacts


# sample contacts responses
=begin
Bad email
=========
<?xml version="1.0" encoding="utf-8" ?>
<ns1:GetContactsResponse xmlns:ns1="Plaxo">
  <response>
    <code>401</code>
    <subCode>1</subCode>
    <message>User not found.</message>
  </response>
</ns1:GetContactsResponse>


Bad password
============
<?xml version="1.0" encoding="utf-8" ?>
<ns1:GetContactsResponse xmlns:ns1="Plaxo">
  <response>
    <code>401</code>
    <subCode>4</subCode>
    <message>Bad password or security token.</message>
  </response>
</ns1:GetContactsResponse>


Success
=======
<?xml version="1.0" encoding="utf-8" ?>
<ns1:GetContactsResponse xmlns:ns1="Plaxo">

  <response>
    <code>200</code>
    <message>OK</message>
    <userId>77311236242</userId>
  </response>
  
  <contacts>

    <contact>
      <itemId>61312569</itemId>
      <displayName>Joe Blow1</displayName>
      <fullName>Joe Blow1</fullName>
      <firstName>Joe</firstName>
      <lastName>Blow1</lastName>
      <homeEmail1>joeblow1@mailinator.com</homeEmail1>
      <email1>joeblow1@mailinator.com</email1>
      <folderId>5291351</folderId>
    </contact>
    
    <contact>
      <itemId>61313159</itemId>
      <displayName>Joe Blow2</displayName>
      <fullName>Joe Blow2</fullName>
      <firstName>Joe</firstName>
      <lastName>Blow2</lastName>
      <homeEmail1>joeblow2@mailinator.com</homeEmail1>
      <email1>joeblow2@mailinator.com</email1>
      <folderId>5291351</folderId>
    </contact>
    
  </contacts>
  
  <totalCount>2</totalCount>
  <editCounter>3</editCounter>
  
</ns1:GetContactsResponse>
=end