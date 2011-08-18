require 'test_helper'

class RootControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should save a widget" do
    get :make_widget, :name => 'my widget'
    assert_response :success
    assert_equal 'Saved my widget', response.body
  end
end
