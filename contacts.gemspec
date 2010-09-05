Gem::Specification.new do |s|
  s.name = "contacts"
  s.version = "1.2.4"
  s.date = "2010-07-06"
  s.summary = "A universal interface to grab contact list information from various providers including Yahoo, AOL, Gmail, Hotmail, and Plaxo."
  s.email = "lucas@rufy.com"
  s.homepage = "http://github.com/cardmagic/contacts"
  s.description = "A universal interface to grab contact list information from various providers including Yahoo, AOL, Gmail, Hotmail, and Plaxo."
  s.has_rdoc = false
  s.authors = ["Lucas Carlson"]
  s.files = Dir['{examples,lib,test}/**/*'] + %w{LICENSE Rakefile README}
  s.add_dependency("json", ">= 1.1.1")
  s.add_dependency('gdata', '>= 1.1.1')
  s.add_dependency('hpricot', '~> 0.8.2')
  s.add_dependency('httparty', '~> 0.6.1')
end
