class Contacts
  class Yahoo < Base
    URL                 = "http://mail.yahoo.com/"
    LOGIN_URL           = "https://login.yahoo.com/config/login"
    ADDRESS_BOOK_URL    = "http://address.mail.yahoo.com/?.rand=430244936"
    CONTACT_LIST_URL    = "http://address.mail.yahoo.com/?_src=&_crumb=crumb&sortfield=3&bucket=1&scroll=1&VPC=social_list&.r=time"
    PROTOCOL_ERROR      = "Yahoo has changed its protocols, please upgrade this library first. If that does not work, dive into the code and submit a patch at http://github.com/cardmagic/contacts"
    INVALID_PASS        = '<div class="yregertxt"><strong><strong>Invalid ID or password.</strong><br/> Please try again using your full Yahoo! ID.</strong></div>'
    NOT_YET_TAKEN       = '<div class="yregertxt"><strong><strong>This ID is not yet taken.</strong><br>Are you trying to '
    
    def real_connect(attempt_count=0)
      postdata =  ".tries=2&.src=ym&.md5=&.hash=&.js=&.last=&promo=&.intl=us&.bypass="
      postdata += "&.partner=&.u=4eo6isd23l8r3&.v=0&.challenge=gsMsEcoZP7km3N3NeI4mX"
      postdata += "kGB7zMV&.yplus=&.emailCode=&pkg=&stepid=&.ev=&hasMsgr=1&.chkP=Y&."
      postdata += "done=#{CGI.escape(URL)}&login=#{CGI.escape(login)}&passwd=#{CGI.escape(password)}"
      
      data, resp, cookies, forward = post(LOGIN_URL, postdata)
      
      if data.index(INVALID_PASS) || data.index(NOT_YET_TAKEN)
        if attempt_count < 1
          sleep(5)
          return real_connect(attempt_count + 1)
        else
          raise AuthenticationError, "Username and password do not match"
        end
      elsif data.index("Sign in") && data.index("to Yahoo!")
        raise AuthenticationError, "Required field must not be blank"
      elsif !data.match(/uncompressed\/chunked/)
        raise ConnectionError, PROTOCOL_ERROR
      elsif cookies == ""
        raise ConnectionError, PROTOCOL_ERROR
      end
      
      data, resp, cookies, forward = get(forward, cookies, LOGIN_URL)
      
      if resp.code_type != Net::HTTPOK
        raise ConnectionError, PROTOCOL_ERROR
      end
      
      @cookies = cookies
    end
    
    def contacts       
      return @contacts if @contacts
      if connected?
        # first, get the addressbook site with the new crumb parameter
        url = URI.parse(address_book_url)
        http = open_http(url)
        resp, data = http.get("#{url.path}?#{url.query}",
          "Cookie" => @cookies
        )

        if resp.code_type != Net::HTTPOK
          raise ConnectionError, self.class.const_get(:PROTOCOL_ERROR)
        end

        crumb = data.to_s[/dotCrumb:   '(.*?)'/][13...-1]

        # now proceed with the new ".crumb" parameter to get the csv data
        url = URI.parse(contact_list_url.sub("_crumb=crumb","_crumb=#{crumb}").sub("time", Time.now.to_f.to_s.sub(".","")[0...-2]))
        http = open_http(url)
        resp, more_data = http.get("#{url.path}?#{url.query}",
          "Cookie" => @cookies,
          "X-Requested-With" => "XMLHttpRequest",
          "Referer" => address_book_url
        )

        if resp.code_type != Net::HTTPOK
        raise ConnectionError, self.class.const_get(:PROTOCOL_ERROR)
        end
        
        parse data
        
        parse more_data
        
        if more_data =~ /"TotalABContacts":(\d+)/
          total = $1.to_i
          ((total / 50)).times do |i|
            # now proceed with the new ".crumb" parameter to get the csv data
            url = URI.parse(contact_list_url.sub("bucket=1","bucket=#{i+1}").sub("_crumb=crumb","_crumb=#{crumb}").sub("time", Time.now.to_f.to_s.sub(".","")[0...-2]))
            http = open_http(url)
            resp, more_data = http.get("#{url.path}?#{url.query}",
              "Cookie" => @cookies,
              "X-Requested-With" => "XMLHttpRequest",
              "Referer" => address_book_url
            )

            if resp.code_type != Net::HTTPOK
            raise ConnectionError, self.class.const_get(:PROTOCOL_ERROR)
            end
                        
            parse more_data
          end
        end
        
        @contacts
      end
    end

  private
    
    def parse(data, options={})
      @contacts ||= []
      if data =~ /var InitialContacts = (\[.*?\]);/
        @contacts += Contacts.parse_json($1).select{|contact|!contact["email"].to_s.empty?}.map{|contact|[contact["contactName"], contact["email"]]}
      elsif data =~ /^\{"response":/
        @contacts += Contacts.parse_json(data)["response"]["ResultSet"]["Contacts"].to_a.select{|contact|!contact["email"].to_s.empty?}.map{|contact|[contact["contactName"], contact["email"]]}
      else
        @contacts
      end
    end
    
  end

  TYPES[:yahoo] = Yahoo
end