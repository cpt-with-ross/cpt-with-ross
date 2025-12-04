require "application_system_test_case"

class ImpactStatementsTest < ApplicationSystemTestCase
  setup do
    @impact_statement = impact_statements(:one)
  end

  test "visiting the index" do
    visit impact_statements_url
    assert_selector "h1", text: "Impact statements"
  end

  test "should create impact statement" do
    visit impact_statements_url
    click_on "New impact statement"

    fill_in "Content", with: @impact_statement.content
    fill_in "IndexEvent", with: @impact_statement.index_event_id
    click_on "Create Impact statement"

    assert_text "Impact statement was successfully created"
    click_on "Back"
  end

  test "should update Impact statement" do
    visit impact_statement_url(@impact_statement)
    click_on "Edit this impact statement", match: :first

    fill_in "Content", with: @impact_statement.content
    fill_in "IndexEvent", with: @impact_statement.index_event_id
    click_on "Update Impact statement"

    assert_text "Impact statement was successfully updated"
    click_on "Back"
  end

  test "should destroy Impact statement" do
    visit impact_statement_url(@impact_statement)
    click_on "Destroy this impact statement", match: :first

    assert_text "Impact statement was successfully destroyed"
  end
end
