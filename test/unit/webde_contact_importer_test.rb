dir = File.dirname(__FILE__)
require "#{dir}/../test_helper"
require 'contacts'

class WebdeContactImporterTest < ContactImporterTestCase
  def setup
    super
    @account = TestAccounts[:webde]
  end

  def test_successful_login
    assert Contacts.new(:webde, @account.username, @account.password).connected?
  end
  
  def test_importer_fails_with_invalid_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:webde, @account.username, "wrong_password")
    end
  end
  
  def test_importer_fails_with_blank_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:webde, @account.username, "")
    end
  end
  
  def test_importer_fails_with_blank_username
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:webde, "", @account.password)
    end
  end

  def test_fetch_contacts
    contacts = Contacts.new(:webde, @account.username, @account.password).contacts
    @account.contacts.each do |contact|
      assert contacts.include?(contact), "Could not find: #{contact.inspect} in #{contacts.inspect}"
    end
  end
end