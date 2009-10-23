# Use ActiveSupport's version of JSON if available
if Object.const_defined?('ActiveSupport') && ActiveSupport.const_defined?('JSON') && ActiveSupport::JSON.is_a?(Class)
  puts JSON.class
  class JSON
    def self.parse(i)
      ActiveSupport::JSON.decode(i)
    end
  end
else
  require 'json/add/rails'
end

class Hash
  def to_query_string
    u = ERB::Util.method(:u)
    map { |k, v|
      u.call(k) + "=" + u.call(v)
    }.join("&")
  end
end

class Contacts
  class Gmail < Base
    URL                 = "https://mail.google.com/mail/"
    LOGIN_URL           = "https://www.google.com/accounts/ServiceLoginAuth"
    LOGIN_REFERER_URL   = "https://www.google.com/accounts/ServiceLogin?service=mail&passive=true&rm=false&continue=http%3A%2F%2Fmail.google.com%2Fmail%2F%3Fui%3Dhtml%26zy%3Dl&bsv=zpwhtygjntrz&scc=1&ltmpl=default&ltmplcache=2"
    CONTACT_LIST_URL    = "https://mail.google.com/mail/contacts/data/contacts?thumb=true&show=ALL&enums=true&psort=Name&max=10000&out=js&rf=&jsx=true"
    PROTOCOL_ERROR      = "Gmail has changed its protocols, please upgrade this library first. If that does not work, dive into the code and submit a patch at http://github.com/cardmagic/contacts"
    
    def real_connect
      postdata = {
        "Email" => login,
        "Passwd" => password,
        "PersistentCookie" => "yes",
        "asts" => "",
        "rmShown" => "1",
        "signIn" => CGI.escape("Sign in")
      }
            
      # Get this cookie and stick it in the form to confirm to Google that your cookies work
      data, resp, cookies, forward = get(LOGIN_REFERER_URL)
      postdata["GALX"] = cookie_hash_from_string(cookies)["GALX"]

      data, resp, cookies, forward, old_url = post(LOGIN_URL, postdata.to_query_string, cookies, LOGIN_REFERER_URL) + [LOGIN_REFERER_URL]
      
      if data.index("Username and password do not match")
        raise AuthenticationError, "Username and password do not match"
      elsif data.index("The username or password you entered is incorrect")
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
      
      cookies = remove_cookie("LSID", cookies)
      cookies = remove_cookie("GV", cookies)

      @cookies = cookies
    end
    
  private
    
    def parse(data, options)
      data.gsub!(/^while \(true\); &&&START&&&/, '')
      data.gsub!(/ &&&END&&&$/, '')
      data.gsub!(/\t/, ' ') # tabs in the note field cause errors with JSON.parse
      data.gsub!(/[\t\x00-\x1F]/, " ") # strip control characters
      
      @contacts = JSON.parse(data)['Body']['Contacts'] || {}

      # Determine in which format to return the data.
      
      # Return the full JSON Hash. 
      return @contacts if(options[:details])

      # Default format.
      # ['Name', 'Email1', 'Email2', ...]
      if @contacts != nil
        @contacts = @contacts.delete_if {|c| c["Emails"].nil?}.map do |c|
          name, emails = c.values_at "Name", "Emails"
          # emails are returned in a form of
          # [{"Address"=>"home.email@gmail.com"}, {"Type"=>{"Id"=>"WORK"}, "Address"=>"work.email@gmail.com"}]
          emails = emails.collect{|a| a.values_at("Address")}
          [name, emails].flatten
        end
      else
        []
      end
    end    
  end

  TYPES[:gmail] = Gmail
end