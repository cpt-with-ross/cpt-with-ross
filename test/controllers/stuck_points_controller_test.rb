require "test_helper"

class StuckPointsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @stuck_point = stuck_points(:one)
  end

  test "should get index" do
    get stuck_points_url
    assert_response :success
  end

  test "should get new" do
    get new_stuck_point_url
    assert_response :success
  end

  test "should create stuck_point" do
    assert_difference("StuckPoint.count") do
      post stuck_points_url, params: { stuck_point: { belief: @stuck_point.belief, belief_type: @stuck_point.belief_type, resolved: @stuck_point.resolved, title: @stuck_point.title, index_event_id: @stuck_point.index_event_id } }
    end

    assert_redirected_to stuck_point_url(StuckPoint.last)
  end

  test "should show stuck_point" do
    get stuck_point_url(@stuck_point)
    assert_response :success
  end

  test "should get edit" do
    get edit_stuck_point_url(@stuck_point)
    assert_response :success
  end

  test "should update stuck_point" do
    patch stuck_point_url(@stuck_point), params: { stuck_point: { belief: @stuck_point.belief, belief_type: @stuck_point.belief_type, resolved: @stuck_point.resolved, title: @stuck_point.title, index_event_id: @stuck_point.index_event_id } }
    assert_redirected_to stuck_point_url(@stuck_point)
  end

  test "should destroy stuck_point" do
    assert_difference("StuckPoint.count", -1) do
      delete stuck_point_url(@stuck_point)
    end

    assert_redirected_to stuck_points_url
  end
end
