require 'test_helper'

class WidgetTest < ActiveSupport::TestCase
  def new_widget
    Widget.new :name => "test widget"
  end

  test "Widget creation" do
    assert new_widget.save, "expected a new widget to be valid"
    assert_equal 1, Widget.count
  end
end
