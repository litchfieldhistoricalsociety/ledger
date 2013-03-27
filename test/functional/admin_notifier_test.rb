require 'test_helper'

class AdminNotifierTest < ActionMailer::TestCase
  test "no_solr" do
    mail = AdminNotifier.no_solr
    assert_equal "No solr", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
