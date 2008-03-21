class Contacts
  class Hotmail < Base
    URL                 = "http://login.live.com/login.srf?id=2"
    OLD_CONTACT_LIST_URL = "http://%s/cgi-bin/addresses"
    NEW_CONTACT_LIST_URL = "http://%s/mail/GetContacts.aspx"
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
      
      data, resp, cookies, forward, old_url = get("http://mail.live.com/mail", cookies)
      data, resp, cookies, forward, old_url = get(forward, cookies)
      
      @domain = URI.parse(forward).host
      @cookies = cookies
    rescue AuthenticationError => m
      if @attempt == 1
        retry
      else
        raise m
      end
    end
    
  private
    
    def contact_list_url
      NEW_CONTACT_LIST_URL % @domain
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
      data = CSV.parse(data.join("\r\n").gsub('"', ''), ';')
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