require "test_helper"

class TraumasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @trauma = traumas(:one)
  end

  test "should get index" do
    get traumas_url
    assert_response :success
  end

  test "should get new" do
    get new_trauma_url
    assert_response :success
  end

  test "should create trauma" do
    assert_difference("Trauma.count") do
      post traumas_url, params: { trauma: { event_date: @trauma.event_date, name: @trauma.name, user_id: @trauma.user_id } }
    end

    assert_redirected_to trauma_url(Trauma.last)
  end

  test "should show trauma" do
    get trauma_url(@trauma)
    assert_response :success
  end

  test "should get edit" do
    get edit_trauma_url(@trauma)
    assert_response :success
  end

  test "should update trauma" do
    patch trauma_url(@trauma), params: { trauma: { event_date: @trauma.event_date, name: @trauma.name, user_id: @trauma.user_id } }
    assert_redirected_to trauma_url(@trauma)
  end

  test "should destroy trauma" do
    assert_difference("Trauma.count", -1) do
      delete trauma_url(@trauma)
    end

    assert_redirected_to traumas_url
  end
end
