require 'csv'
require 'mechanize'

class Contacts
  class WP < Base

    LOGIN_URL = "https://poczta.wp.pl"
    AUTH_ERROR_URL = "http://profil.wp.pl/login_poczta.html"
    ADDRESS_BOOK_URL = "http://ksiazka-adresowa.wp.pl/import-export.html"

    def real_connect
      begin
        @agent = Mechanize.new
        page = @agent.get(LOGIN_URL)
        form = page.forms.first
        form.login_username = @login
        form.login_password = @password
        @page = form.submit
      if page.uri.to_s == AUTH_ERROR_URL
        raise AuthenticationError, "Username and password do not match"
      end
      end
    end

    def contacts
      page = @agent.get(ADDRESS_BOOK_URL)
      form = page.forms.last
      form.gr_id = 0
      form.program = 'gm'
      con = CSV.parse(form.submit.body)
      @contacts = []
      con[1..-1].each do |row|
        @contacts << [row[0], row[1]]
      end
      @contacts
    end

  end

  TYPES[:wp] = WP
end
