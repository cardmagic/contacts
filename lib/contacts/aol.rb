class Contacts
  require 'hpricot'
  require 'csv'
  class Aol < Base
    URL                 = "http://www.aol.com/"
    LOGIN_URL           = "https://my.screenname.aol.com/_cqr/login/login.psp"
    LOGIN_REFERER_URL   = "http://webmail.aol.com/"
    LOGIN_REFERER_PATH = "sitedomain=sns.webmail.aol.com&lang=en&locale=us&authLev=0&uitype=mini&loginId=&redirType=js&xchk=false"
    PROTOCOL_ERROR      = "AOL has changed its protocols, please upgrade this library first. If that does not work, dive into the code and submit a patch at http://github.com/cardmagic/contacts"
    
    def real_connect
      if login.strip =~ /^(.+)@aol\.com$/ # strip off the @aol.com for AOL logins
        login = $1
      end

      postdata = {
        "loginId" => login,
        "password" => password,
        "rememberMe" => "on",
        "_sns_fg_color_" => "",
        "_sns_err_color_" => "",
        "_sns_link_color_" => "",
        "_sns_width_" => "",
        "_sns_height_" => "",
        "offerId" => "mail-second-en-us",
        "_sns_bg_color_" => "",
        "sitedomain" => "sns.webmail.aol.com",
        "regPromoCode" => "",
        "mcState" => "initialized",
        "uitype" => "std",
        "siteId" => "",
        "lang" => "en",
        "locale" => "us",
        "authLev" => "0",
        "siteState" => "",
        "isSiteStateEncoded" => "false",
        "use_aam" => "0",
        "seamless" => "novl",
        "aolsubmit" => CGI.escape("Sign In"),
        "idType" => "SN",
        "usrd" => "",
        "doSSL" => "",
        "redirType" => "",
        "xchk" => "false"
      }
 
      # Get this cookie and stick it in the form to confirm to Aol that your cookies work
      data, resp, cookies, forward = get(URL)
      postdata["stips"] = cookie_hash_from_string(cookies)["stips"]
      postdata["tst"] = cookie_hash_from_string(cookies)["tst"]
 
      data, resp, cookies, forward, old_url = get(LOGIN_REFERER_URL, cookies) + [URL]
      until forward.nil?
        data, resp, cookies, forward, old_url = get(forward, cookies, old_url) + [forward]
      end
      
      data, resp, cookies, forward, old_url = get("#{LOGIN_URL}?#{LOGIN_REFERER_PATH}", cookies) + [LOGIN_REFERER_URL]
      until forward.nil?
        data, resp, cookies, forward, old_url = get(forward, cookies, old_url) + [forward]
      end
 
      doc = Hpricot(data)
      (doc/:input).each do |input|
        postdata["usrd"] = input.attributes["value"] if input.attributes["name"] == "usrd"
      end
      # parse data for <input name="usrd" value="2726212" type="hidden"> and add it to the postdata
 
      postdata["SNS_SC"] = cookie_hash_from_string(cookies)["SNS_SC"]
      postdata["SNS_LDC"] = cookie_hash_from_string(cookies)["SNS_LDC"]
      postdata["LTState"] = cookie_hash_from_string(cookies)["LTState"]
      # raise data.inspect
      
      data, resp, cookies, forward, old_url = post(LOGIN_URL, h_to_query_string(postdata), cookies, LOGIN_REFERER_URL) + [LOGIN_REFERER_URL]
      
      until forward.nil?
        data, resp, cookies, forward, old_url = get(forward, cookies, old_url) + [forward]
      end
      
      if data.index("Incorrect Username or Password.")
        raise AuthenticationError, "Username and password do not match"
      elsif data.index("Required field must not be blank")
        raise AuthenticationError, "Login and password must not be blank"
      elsif data.index("errormsg_0_logincaptcha")
        raise AuthenticationError, "Captcha error"
      elsif data.index("Invalid request")
        raise ConnectionError, PROTOCOL_ERROR
      elsif cookies == ""
        raise ConnectionError, PROTOCOL_ERROR
      end

      @aol_num = data.match(/URL=\"http:\/\/mail.aol.com\/(.*)\/aol-6\/en-us\/common\/error.aspx\?/)[1]
      @contact_list_url    = "http://mail.aol.com/#{@aol_num}/aol-6/en-us/Lite/ContactList.aspx?folder=Inbox&showUserFolders=False"
      @contact_list_csv_url = "http://mail.aol.com/#{@aol_num}/aol-6/en-us/Lite/ABExport.aspx?command=all"

      @cookies = cookies
    end
 
    def contacts
      postdata = {
        "file" => 'contacts',
        "fileType" => 'csv'
      }
 
      return @contacts if @contacts
      if connected?
        data, resp, cookies, forward, old_url = get(@contact_list_url, @cookies, @contact_list_url) + [@contact_list_url]
 
        until forward.nil?
          data, resp, cookies, forward, old_url = get(forward, cookies, old_url) + [forward]
        end
        
        if resp.code_type != Net::HTTPOK
          raise ConnectionError, self.class.const_get(:PROTOCOL_ERROR)
        end
 
        # parse data and grab <input name="user" value="8QzMPIAKs2" type="hidden">
        doc = Hpricot(data)
        (doc/:input).each do |input|
          postdata["user"] = input.attributes["value"] if input.attributes["name"] == "user"
        end
        
        data, resp, cookies, forward, old_url = get(@contact_list_csv_url, @cookies, @contact_list_url) + [@contact_list_url]
 
        until forward.nil?
          data, resp, cookies, forward, old_url = get(forward, cookies, old_url) + [forward]
        end
        
        if data.include?("error.gif")
          raise AuthenticationError, "Account invalid"
        end
        
        parse data
      end
    end
  private
    
    def parse(data, options={})
      begin
        @contacts = []
        FasterCSV.parse(data) do |person|
          @contacts << ["#{person[0]} #{person[1]}", person[4]] if person[4] && !person[4].empty?
        end
        @contacts
      rescue
        parsed_data = CSV::Reader.parse(data)
        col_names = parsed_data.shift
        @contacts = parsed_data.map do |person|
          ["#{person[0]} #{person[1]}", person[4]] if person[4] && !person[4].empty?
        end.compact
      end
    end    
 
    def h_to_query_string(hash)
      u = ERB::Util.method(:u)
      hash.map { |k, v|
        u.call(k) + "=" + u.call(v)
      }.join("&")
    end
  end
 
  TYPES[:aol] = Aol
end