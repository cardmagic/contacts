require 'csv'

class Contacts
  class Mailru < Base
    LOGIN_URL = "https://auth.mail.ru/cgi-bin/auth"
    ADDRESS_BOOK_URL = "http://win.mail.ru/cgi-bin/abexport/addressbook.csv"

    attr_accessor :cookies

    def real_connect
      username = login
      
      postdata =  "Login=%s&Domain=%s&Password=%s" % [
        CGI.escape(username),
        CGI.escape(domain_param(username)),
        CGI.escape(password)
      ]

      data, resp, self.cookies, forward = post(LOGIN_URL, postdata, "")

      if data.index("fail=1")
        raise AuthenticationError, "Username and password do not match"
      elsif cookies == "" or data == ""
        raise ConnectionError, PROTOCOL_ERROR
      end

      data, resp, cookies, forward = get(login_token_link(data), login_cookies.join(';'))
    end

    def contacts
      postdata = "confirm=1&abtype=6"
      data, resp, cookies, forward = post(ADDRESS_BOOK_URL, postdata, login_cookies.join(';'))

      @contacts = []
      CSV.parse(data) do |row|
        @contacts << [row[0], row[4]] unless header_row?(row)
      end

      @contacts
    end

    def skip_gzip?
      true
    end

    private
    def login_token_link(data)
      data.match(/url=(.+)\">/)[1]
    end

    def login_cookies
      self.cookies.split(';').collect{|c| c if (c.include?('t=') or c.include?('Mpop='))}.compact.collect{|c| c.strip}
    end

    def header_row?(row)
      row[0] == 'AB-Name'
    end

    def domain_param(login)
      login.include?('@') ?
        login.match(/.+@(.+)/)[1] :
        'mail.ru'
    end

  end

  TYPES[:mailru] = Mailru
end