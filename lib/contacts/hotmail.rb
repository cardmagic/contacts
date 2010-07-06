class Contacts
  class Hotmail < Base
    URL                 = "https://login.live.com/login.srf?id=2"
    OLD_CONTACT_LIST_URL = "http://%s/cgi-bin/addresses"
    NEW_CONTACT_LIST_URL = "http://%s/mail/GetContacts.aspx"
    CONTACT_LIST_URL = "http://mpeople.live.com/default.aspx?pg=0" 
    COMPOSE_URL         = "http://%s/cgi-bin/compose?"
    PROTOCOL_ERROR      = "Hotmail has changed its protocols, please upgrade this library first. If that does not work, report this error at http://rubyforge.org/forum/?group_id=2693"
    PWDPAD = "IfYouAreReadingThisYouHaveTooMuchFreeTime"
    MAX_HTTP_THREADS    = 8
    
    def real_connect
      data, resp, cookies, forward = get(URL)
      old_url = URL
      until forward.nil?
        data, resp, cookies, forward, old_url = get(forward, cookies, old_url) + [forward]
      end
      
      postdata =  "PPSX=%s&PwdPad=%s&login=%s&passwd=%s&LoginOptions=2&PPFT=%s" % [
        CGI.escape(data.split("><").grep(/PPSX/).first[/=\S+$/][2..-3]),
        PWDPAD[0...(PWDPAD.length-@password.length)],
        CGI.escape(login),
        CGI.escape(password),
        CGI.escape(data.split("><").grep(/PPFT/).first[/=\S+$/][2..-3])
      ]
      
      form_url = data.split("><").grep(/form/).first.split[5][8..-2]
      data, resp, cookies, forward = post(form_url, postdata, cookies)
      
      old_url = form_url
      until cookies =~ /; PPAuth=/ || forward.nil?
        data, resp, cookies, forward, old_url = get(forward, cookies, old_url) + [forward]
      end
      
      if data.index("The e-mail address or password is incorrect")
        raise AuthenticationError, "Username and password do not match"
      elsif data != ""
        raise AuthenticationError, "Required field must not be blank"
      elsif cookies == ""
        raise ConnectionError, PROTOCOL_ERROR
      end
            
      data, resp, cookies, forward = get("http://mail.live.com/mail", cookies)
      until forward.nil?
        data, resp, cookies, forward, old_url = get(forward, cookies, old_url) + [forward]
      end
      
      @domain = URI.parse(old_url).host
      @cookies = cookies
    rescue AuthenticationError => m
      if @attempt == 1
        retry
      else
        raise m
      end
    end
    
    def contacts(options = {})
      if connected?
        url = URI.parse(contact_list_url)
        data, resp, cookies, forward = get( contact_list_url, @cookies )
        
        if resp.code_type != Net::HTTPOK
          raise ConnectionError, self.class.const_get(:PROTOCOL_ERROR)
        end
        
        @contacts = []
        build_contacts = []
        go = true
        index = 0
        
        while(go) do
          go = false
          url = URI.parse(get_contact_list_url(index))
          http = open_http(url)
          resp, data = http.get(get_contact_list_url(index), "Cookie" => @cookies)
          
          email_match_text_beginning = Regexp.escape("http://m.mail.live.com/?rru=compose&amp;to=")
          email_match_text_end = Regexp.escape("&amp;")
          
          raw_html = resp.body.split("
").grep(/(?:e|dn)lk[0-9]+/)
          raw_html.inject(-1) do |memo, row|
            c_info = row.match(/(e|dn)lk([0-9])+/)
            
            # Same contact, or different?
            build_contacts << [] if memo != c_info[2]
            
            # Grab info
            case c_info[1]
              when "e" # Email
                build_contacts.last[1] = row.match(/#{email_match_text_beginning}(.*)#{email_match_text_end}/)[1]
              when "dn" # Name
                build_contacts.last[0] = row.match(/<a[^>]*>(.+)<\/a>/)[1]
            end
            
            # Set memo to contact id
            c_info[2]
          end
          
          go = resp.body.include?("ContactList_next")
          index += 1
        end
        
        build_contacts.each do |contact|
          unless contact[1].nil?
            # Only return contacts with email addresses
            contact[1] = CGI::unescape(contact[1])
            @contacts << contact
          end
        end
        
        return @contacts
      end
    end
    
    def get_contact_list_url(index) 
      "http://mpeople.live.com/default.aspx?pg=#{index}"
    end
    
    private
    
    TYPES[:hotmail] = Hotmail
  end
end