require "test_helper"

class IndexEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @index_event = index_events(:one)
  end

  test "should get index" do
    get index_events_url
    assert_response :success
  end

  test "should get new" do
    get new_index_event_url
    assert_response :success
  end

  test "should create index_event" do
    assert_difference("IndexEvent.count") do
      post index_events_url, params: { index_event: { event_date: @index_event.event_date, name: @index_event.name, user_id: @index_event.user_id } }
    end

    assert_redirected_to index_event_url(IndexEvent.last)
  end

  test "should show index_event" do
    get index_event_url(@index_event)
    assert_response :success
  end

  test "should get edit" do
    get edit_index_event_url(@index_event)
    assert_response :success
  end

  test "should update index_event" do
    patch index_event_url(@index_event), params: { index_event: { event_date: @index_event.event_date, name: @index_event.name, user_id: @index_event.user_id } }
    assert_redirected_to index_event_url(@index_event)
  end

  test "should destroy index_event" do
    assert_difference("IndexEvent.count", -1) do
      delete index_event_url(@index_event)
    end

    assert_redirected_to index_events_url
  end
end
