require "application_system_test_case"

class TraumasTest < ApplicationSystemTestCase
  setup do
    @trauma = traumas(:one)
  end

  test "visiting the index" do
    visit traumas_url
    assert_selector "h1", text: "Traumas"
  end

  test "should create trauma" do
    visit traumas_url
    click_on "New trauma"

    fill_in "Event date", with: @trauma.event_date
    fill_in "Name", with: @trauma.name
    fill_in "User", with: @trauma.user_id
    click_on "Create Trauma"

    assert_text "Trauma was successfully created"
    click_on "Back"
  end

  test "should update Trauma" do
    visit trauma_url(@trauma)
    click_on "Edit this trauma", match: :first

    fill_in "Event date", with: @trauma.event_date
    fill_in "Name", with: @trauma.name
    fill_in "User", with: @trauma.user_id
    click_on "Update Trauma"

    assert_text "Trauma was successfully updated"
    click_on "Back"
  end

  test "should destroy Trauma" do
    visit trauma_url(@trauma)
    click_on "Destroy this trauma", match: :first

    assert_text "Trauma was successfully destroyed"
  end
end
