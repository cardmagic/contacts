class Contacts
  class Webde < Base
    LOGIN_URL = "https://login.web.de/intern/login/"
    JUMP_URL = "https://uas2.uilogin.de/intern/jump/"
    ADDRESSBOOK_URL = "https://adressbuch.web.de/exportcontacts"
    
    def real_connect
      postdata = "service=freemail&server=%s&password=%s&username=%s" % [
        CGI.escape('https://freemail.web.de'),
        CGI.escape(password),
        CGI.escape(login)
      ]

      # send login
      data, resp, cookies, forward = post(LOGIN_URL, postdata)

      if forward.include?("logonfailed")
        raise AuthenticationError, "Username and password do not match"
      end

      # request session from login service
      data, resp, cookies, forward = get forward

      # start mail app session
      data, resp, cookies, forward = get forward

      @si = forward.match(/si=([^&]+)/)[1]
    end

    def connected?
      @si && @si.length > 0
    end

    def contacts
      conect_to_addressbook
      @contacts = []
      if @sessionid
        CSV.parse(get_entries_from_addressbook) do |row|
          @contacts << ["#{row[2]} #{row[0]}", row[9]] unless header_row?(row)
        end
      end
      
      @contacts
    end

    private
    
    def header_row?(row)
      row[0] == 'Nachname'
    end

    def conect_to_addressbook
      data, resp, cookies, forward = get JUMP_URL + "?serviceID=comsaddressbook-live.webde&session=#{@si}&server=https://freemailng2901.web.de&partnerdata="
      @sessionid = forward.match(/session=([^&]+)/)[1]
    end
    
    def get_entries_from_addressbook 
      postdata = "language=de&raw_format=csv_Outlook2003&session=#{@sessionid}&what=PERSON"
      data, resp, cookies, forward = post ADDRESSBOOK_URL, postdata
      data
    end
  end
  
  TYPES[:webde] = Webde
end