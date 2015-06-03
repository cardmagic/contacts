$:.unshift(File.dirname(__FILE__)+"/contacts/")

require 'rubygems'
require 'bundler/setup'

require 'base'
require 'json_picker'

Contacts.autoload :Aol, 'aol'
Contacts.autoload :Gmail, 'gmail'
Contacts.autoload :Hotmail, 'hotmail'
Contacts.autoload :Yahoo, 'yahoo'
Contacts.autoload :Plaxo, 'plaxo'
Contacts.autoload :Mailru, 'mailru'
