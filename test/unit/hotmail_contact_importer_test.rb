dir = File.dirname(__FILE__)
require "#{dir}/../test_helper"
require 'contacts'

class HotmailContactImporterTest < ContactImporterTestCase
  def setup
    super
    @account = TestAccounts[:hotmail]
  end

  def test_successful_login
    Contacts.new(:hotmail, @account.username, @account.password)
  end

  def test_importer_fails_with_invalid_password
    assert_raise(Contacts::AuthenticationError) do
      Contacts.new(:hotmail, @account.username,"wrong_password")
    end
  end

  def test_fetch_contacts
    contacts = Contacts.new(:hotmail, @account.username, @account.password).contacts
    assert_equal @account.contacts, contacts
  end
end
