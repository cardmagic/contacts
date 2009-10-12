$:.unshift(File.dirname(__FILE__)+"/contacts/")

require 'rubygems'

gem 'gdata', '1.1.0'
require 'gdata'

require 'base'
require 'gmail'
require 'hotmail'
require 'yahoo'
require 'plaxo'