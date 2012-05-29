class Contacts
  class Gmx < Base
    LOGIN_URL = 'https://service.gmx.net/de/cgi/login'
    JUMP_URL = 'https://uas2.uilogin.de/intern/jump' #used for unified address service auth
    MAIL_FOLDER_URL = 'http://service.gmx.net/de/cgi/g.fcgi/mail/index'
    MAIL_FOLDER_PARAMS = "folder=%s&allfolders=false&first=%s&CUSTOMERNO=%s&t=%s"
    
    def real_connect
      postdata = "AREA=1&id=%s&p=%s" % [
        CGI.escape(login),
        CGI.escape(password)
      ]
      
      data, resp, @cookies, forward = post(LOGIN_URL, postdata)

      if data.include?("/lose/password") || data.include?("login-failed")
        raise AuthenticationError, "Username and password do not match"
      end
      
      @customerno = forward.match(/CUSTOMERNO=(\d+)/)[1]
      @t = forward.match(/t=([^&]+)/)[1]
    end
    
    def contacts      
      @contacts = {}

      if connected?
        folders.each do |folder|
          contacts_for_folder(folder)
        end        
      end
      
      @contacts.to_a
    end
    
    private
 
    def scan_contacts(html)
      html.scan(/"\"?([\w\.\s-]+)\"?\s&lt;([\w\.-]+@[\w\.-]+\.\w+)(?:&gt;)?"/) do |match|
        @contacts[match[0]] = match[1]
      end
    end
    
    def contacts_for_folder(folder)
      count = 0
      while count < 100 do
        data, resp, cookies, forward = get MAIL_FOLDER_URL + "?" + MAIL_FOLDER_PARAMS % [
          folder,
          count,
          @customerno,
          @t
        ], @cookies
        scan_contacts(data)
        count += 10
      end
    end
   
    def folders
      %w(inbox sent)
    end
    
  end
  
  TYPES[:gmx] = Gmx
end