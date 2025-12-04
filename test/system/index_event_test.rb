require "application_system_test_case"

class IndexEventsTest < ApplicationSystemTestCase
  setup do
    @index_event = index_events(:one)
  end

  test "visiting the index" do
    visit index_events_url
    assert_selector "h1", text: "IndexEvents"
  end

  test "should create index_event" do
    visit index_events_url
    click_on "New index_event"

    fill_in "Event date", with: @index_event.event_date
    fill_in "Name", with: @index_event.name
    fill_in "User", with: @index_event.user_id
    click_on "Create IndexEvent"

    assert_text "IndexEvent was successfully created"
    click_on "Back"
  end

  test "should update IndexEvent" do
    visit index_event_url(@index_event)
    click_on "Edit this index_event", match: :first

    fill_in "Event date", with: @index_event.event_date
    fill_in "Name", with: @index_event.name
    fill_in "User", with: @index_event.user_id
    click_on "Update IndexEvent"

    assert_text "IndexEvent was successfully updated"
    click_on "Back"
  end

  test "should destroy IndexEvent" do
    visit index_event_url(@index_event)
    click_on "Destroy this index_event", match: :first

    assert_text "IndexEvent was successfully destroyed"
  end
end
