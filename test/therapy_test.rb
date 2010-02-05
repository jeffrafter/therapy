require 'test_helper'

class TherapyTest < Test::Unit::TestCase
  should "find the git config" do
    therapy = Therapy.new
    assert_equal "jeffrafter", therapy.config["github.user"]
    assert_equal "Jeff Rafter", therapy.config["user.name"]
  end
  
  should "fetch some issues" do
    therapy = Therapy.new
    therapy.username = "jeffrafter"
    therapy.repository = "therapy"
    therapy.config["github.user"] = nil
    therapy.config["github.token"] = nil
    l = therapy.fetch
    puts "#{l}"
    assert_not_nil l
  end
end
