dir = File.dirname(__FILE__)
require "#{dir}/../test_helper"
require 'contacts'

class YahooContactImporterTest < ContactImporterTestCase
  def setup
    super
    @account = TestAccounts[:yahoo]
  end

  def test_a_successful_login
    Contacts.new(:yahoo, @account.username, @account.password)
  end

  def test_importer_fails_with_invalid_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:yahoo, @account.username, "wrong_password")
    end
    # run the "successful" login test to ensure we reset yahoo's failed login lockout counter
    # See http://www.pivotaltracker.com/story/show/138210
    # yahoo needs some time to unset the failed login state, apparently... 
    # ...1 sec and 5 secs still failed sporadically
    sleep 10
    assert_nothing_raised do
      Contacts.new(:yahoo, @account.username, @account.password)
    end
  end

  def test_a_fetch_contacts
    contacts = Contacts.new(:yahoo, @account.username, @account.password).contacts
    @account.contacts.each do |contact|
      assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
    end
  end
end