require File.dirname(__FILE__)+"/../lib/contacts"

login = ARGV[0]
password = ARGV[1]

Contacts::Gmail.new(login, password).contacts

Contacts.new(:gmail, login, password).contacts

Contacts.new("gmail", login, password).contacts

Contacts.guess(login, password).contacts