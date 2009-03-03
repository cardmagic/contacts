dir = File.dirname(__FILE__)
require "#{dir}/../test_helper"

class TestAccountsTest < ContactImporterTestCase
  def test_test_accounts_loads_data_from_example_accounts_file
    account = TestAccounts.load(File.dirname(__FILE__) + "/../example_accounts.yml")[:gmail]
    
    assert_equal :gmail, account.type
    assert_equal "<changeme>", account.username
    assert_equal "<changeme>", account.password
    assert_equal [["FirstName1 LastName1", "firstname1@example.com"], ["FirstName2 LastName2", "firstname2@example.com"]], account.contacts
  end
  
  def test_test_accounts_blows_up_if_file_doesnt_exist
    assert_raise(RuntimeError) do
      TestAccounts.load("file_that_does_not_exist.yml")
    end
  end
  
  def test_we_can_load_from_account_file
    assert_not_nil TestAccounts[:gmail].username
  end
end