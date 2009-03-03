dir = File.dirname(__FILE__)
Dir["#{dir}/**/*_test.rb"].each do |file|
  require file
end