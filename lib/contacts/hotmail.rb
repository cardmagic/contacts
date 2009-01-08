class Contacts
  class Hotmail < Base
    URL                 = "http://login.live.com/login.srf?id=2"
    OLD_CONTACT_LIST_URL = "http://%s/cgi-bin/addresses"
    NEW_CONTACT_LIST_URL = "http://%s/mail/GetContacts.aspx"
    NEWEST_CONTACT_LIST_URL = "http://%s/mail/options.aspx?subsection=26"
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
      
      if data.index("The e-mail address or password is incorrect")
        raise AuthenticationError, "Username and password do not match"
      elsif data != ""
        raise AuthenticationError, "Required field must not be blank"
      elsif cookies == ""
        raise ConnectionError, PROTOCOL_ERROR
      end
      
      old_url = form_url
      until forward.nil?
        data, resp, cookies, forward, old_url = get(forward, cookies, old_url) + [forward]
      end

=begin      
      if data =~ %r{action="(.*?)"}
        forward = $1
        puts forward
        napexp = CGI.escape(data.to_s[/id="NAPExp" value="(.*?)"/][19...-1])
        nap = CGI.escape(data.to_s[/id="NAP" value="(.*?)"/][16...-1])
        anon = CGI.escape(data.to_s[/id="ANON" value="(.*?)"/][17...-1])
        anonexp = CGI.escape(data.to_s[/id="ANONExp" value="(.*?)"/][20...-1])
        t = CGI.escape(data.to_s[/id="t" value="(.*?)"/][14...-1])
        
        postdata = "NAPExp=%s&NAP=%s&ANON=%s&ANONExp=%s&t=%s" % [ napexp, nap, anon, anonexp, t ]
        puts postdata
        data, resp, cookies, forward, old_url = post(forward, postdata, cookies, old_url) + [forward]
      end

      until forward.nil?
        data, resp, cookies, forward, old_url = get(forward, cookies, old_url) + [forward]
      end
=end
      
      data, resp, cookies, forward = get("http://mail.live.com/mail", cookies)
      until forward.nil?
        data, resp, cookies, forward, old_url = get(forward, cookies, old_url) + [forward]
      end

    # click on 'Contiune' if presented with the Hotmail Listened page
    #  look for the Submit button with a "TakeMeToInbox" name (this should work for other languages)
    if (not old_url.grep(/MessageAtLogin.aspx/).first.nil?)
		
      viewState = data.split(/>\s*?</).grep(/__VIEWSTATE/).first[/value=\".+?\"/][7..-2]
      eventValidation = data.split(/>\s*?</).grep(/__EVENTVALIDATION/).first[/value=\".+?\"/][7..-2]
      continueValue = data.split(/>\s*?</).grep(/TakeMeToInbox/).first[/value=\".+?\"/][7..-2]

      # post back to the same url 
      postdata = "%s=%s&%s=%s&%s=%s" % [
            "__VIEWSTATE", CGI.escape(viewState),
            "__EVENTVALIDATION", CGI.escape(eventValidation),
            CGI.escape("TakeMeToInbox"), CGI.escape(continueValue)
        ]
        data, resp, cookies, forward = post( old_url, postdata, cookies, old_url )
        until forward.nil?
          data, resp, cookies, forward, old_url = get(forward, cookies, old_url) + [forward]
        end
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
      return @contacts if @contacts
      if connected?
        url = URI.parse(contact_list_url)
        data, resp, cookies, forward = get( contact_list_url, @cookies )
        
        if resp.code_type != Net::HTTPOK
          raise ConnectionError, self.class.const_get(:PROTOCOL_ERROR)
        end

        # we have to click on the Export Contacts button to get the csv:
        # Search the content for __VIEWSTATE or __EVENTVALIDATION
        viewState = data.split(/>\s*?</).grep(/__VIEWSTATE/).first[/value=\".+?\"/][7..-2]
        eventValidation = data.split(/>\s*?</).grep(/__EVENTVALIDATION/).first[/value=\".+?\"/][7..-2]
        exportValue = data.split(/>\s*?</).grep(/ctl02\$ExportButton/).first[/value=\".+?\"/][7..-2]
        mt = cookies.split("; ").grep(/mt=/).first[3..-1]
        
        # post back to the same url 
        postdata = "%s=%s&%s=%s&%s=%s&%s=%s" % [
          "__VIEWSTATE", CGI.escape(viewState),
          "__EVENTVALIDATION", CGI.escape(eventValidation),
          CGI.escape("ctl02$ExportButton"), CGI.escape(exportValue),
          "mt", CGI.escape( mt )
        ]
	
        url = URI.parse(contact_list_url)
        http = open_http(url)
        resp, data = http.post("#{url.path}?#{url.query}", postdata,
          "User-Agent" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1) Gecko/20061010 Firefox/2.0",
          "Accept-Encoding" => "gzip",
          "Cookie" => cookies,
          "Referer" => contact_list_url,
          "Content-Type" => 'application/x-www-form-urlencoded'
        )

        data = uncompress(resp, data)
        parse(data, options)
      end
    end


  private
    
    def contact_list_url
      NEWEST_CONTACT_LIST_URL % @domain
    end
    
    def follow_email(data, id, contacts_slot)
      compose_url = COMPOSE_URL % @domain
      postdata = "HrsTest=&to=#{id}&mailto=1&ref=addresses"
      postdata += "&curmbox=00000000-0000-0000-0000-000000000001"

      a = data.split(/>\s*<input\s+/i).grep(/\s+name="a"/i)
      return nil if a.empty?

      a = a[0].match(/\s+value="([a-f0-9]+)"/i) or return nil
      postdata += "&a=#{a[1]}"

      data, resp, @cookies, forward = post(compose_url, postdata, @cookies)
      e = data.split(/>\s*<input\s+/i).grep(/\s+name="to"/i)
      return nil if e.empty?

      e = e[0].match(/\s+value="([^"]+)"/i) or return nil
      @contacts[contacts_slot][1] = e[1] if e[1].match(/@/)
    end

    def parse(data, options={})
      data = data.split("\r\n")
      data = CSV.parse(data.join("\r\n").gsub('"', '').gsub(';', ','), ';')
      col_names = data.shift

      @contacts = data.delete_if{|person|person[0].nil?}.map do |person|
        person = person[0].split(",")
        next unless (idx = person.index('SMTP'))
        [[person[1], person[2], person[3]].delete_if{|i|i.empty?}.join(" "), person[idx - 1]] unless person[idx - 1].nil?
      end.compact 
    end
  end

  TYPES[:hotmail] = Hotmail
end