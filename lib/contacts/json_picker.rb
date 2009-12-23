if !Object.const_defined?('ActiveSupport')
  require 'json'
end

class Contacts
  def self.parse_json( string )
    if Object.const_defined?('ActiveSupport') and
       ActiveSupport.const_defined?('JSON')
      ActiveSupport::JSON.decode( string )
    elsif Object.const_defined?('JSON')
      JSON.parse( string )
    else
      raise 'Contacts requires JSON or Rails (with ActiveSupport::JSON)'
    end
  end
end