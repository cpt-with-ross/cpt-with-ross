require "application_system_test_case"

class AbcWorksheetsTest < ApplicationSystemTestCase
  setup do
    @abc_worksheet = abc_worksheets(:one)
  end

  test "visiting the index" do
    visit abc_worksheets_url
    assert_selector "h1", text: "Abc worksheets"
  end

  test "should create abc worksheet" do
    visit abc_worksheets_url
    click_on "New abc worksheet"

    fill_in "Activating event", with: @abc_worksheet.activating_event
    fill_in "Consequence behaviour", with: @abc_worksheet.consequence_behaviour
    fill_in "Consequence feeling", with: @abc_worksheet.consequence_feeling
    fill_in "Feeling intensity", with: @abc_worksheet.feeling_intensity
    fill_in "Stuck point", with: @abc_worksheet.stuck_point_id
    click_on "Create Abc worksheet"

    assert_text "Abc worksheet was successfully created"
    click_on "Back"
  end

  test "should update Abc worksheet" do
    visit abc_worksheet_url(@abc_worksheet)
    click_on "Edit this abc worksheet", match: :first

    fill_in "Activating event", with: @abc_worksheet.activating_event
    fill_in "Consequence behaviour", with: @abc_worksheet.consequence_behaviour
    fill_in "Consequence feeling", with: @abc_worksheet.consequence_feeling
    fill_in "Feeling intensity", with: @abc_worksheet.feeling_intensity
    fill_in "Stuck point", with: @abc_worksheet.stuck_point_id
    click_on "Update Abc worksheet"

    assert_text "Abc worksheet was successfully updated"
    click_on "Back"
  end

  test "should destroy Abc worksheet" do
    visit abc_worksheet_url(@abc_worksheet)
    click_on "Destroy this abc worksheet", match: :first

    assert_text "Abc worksheet was successfully destroyed"
  end
end
