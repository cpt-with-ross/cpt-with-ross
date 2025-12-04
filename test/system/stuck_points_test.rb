require "application_system_test_case"

class StuckPointsTest < ApplicationSystemTestCase
  setup do
    @stuck_point = stuck_points(:one)
  end

  test "visiting the index" do
    visit stuck_points_url
    assert_selector "h1", text: "Stuck points"
  end

  test "should create stuck point" do
    visit stuck_points_url
    click_on "New stuck point"

    fill_in "Belief", with: @stuck_point.belief
    fill_in "Belief type", with: @stuck_point.belief_type
    check "Resolved" if @stuck_point.resolved
    fill_in "Title", with: @stuck_point.title
    fill_in "Trauma", with: @stuck_point.trauma_id
    click_on "Create Stuck point"

    assert_text "Stuck point was successfully created"
    click_on "Back"
  end

  test "should update Stuck point" do
    visit stuck_point_url(@stuck_point)
    click_on "Edit this stuck point", match: :first

    fill_in "Belief", with: @stuck_point.belief
    fill_in "Belief type", with: @stuck_point.belief_type
    check "Resolved" if @stuck_point.resolved
    fill_in "Title", with: @stuck_point.title
    fill_in "Trauma", with: @stuck_point.trauma_id
    click_on "Update Stuck point"

    assert_text "Stuck point was successfully updated"
    click_on "Back"
  end

  test "should destroy Stuck point" do
    visit stuck_point_url(@stuck_point)
    click_on "Destroy this stuck point", match: :first

    assert_text "Stuck point was successfully destroyed"
  end
end
