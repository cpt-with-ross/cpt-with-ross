require "application_system_test_case"

class AlternativeThoughtsTest < ApplicationSystemTestCase
  setup do
    @alternative_thought = alternative_thoughts(:one)
  end

  test "visiting the index" do
    visit alternative_thoughts_url
    assert_selector "h1", text: "Alternative thoughts"
  end

  test "should create alternative thought" do
    visit alternative_thoughts_url
    click_on "New alternative thought"

    fill_in "Alternative thought", with: @alternative_thought.alternative_thought
    fill_in "Belief rating", with: @alternative_thought.belief_rating
    fill_in "Evidence against", with: @alternative_thought.evidence_against
    fill_in "Evidence for", with: @alternative_thought.evidence_for
    fill_in "Stuck point", with: @alternative_thought.stuck_point_id
    click_on "Create Alternative thought"

    assert_text "Alternative thought was successfully created"
    click_on "Back"
  end

  test "should update Alternative thought" do
    visit alternative_thought_url(@alternative_thought)
    click_on "Edit this alternative thought", match: :first

    fill_in "Alternative thought", with: @alternative_thought.alternative_thought
    fill_in "Belief rating", with: @alternative_thought.belief_rating
    fill_in "Evidence against", with: @alternative_thought.evidence_against
    fill_in "Evidence for", with: @alternative_thought.evidence_for
    fill_in "Stuck point", with: @alternative_thought.stuck_point_id
    click_on "Update Alternative thought"

    assert_text "Alternative thought was successfully updated"
    click_on "Back"
  end

  test "should destroy Alternative thought" do
    visit alternative_thought_url(@alternative_thought)
    click_on "Destroy this alternative thought", match: :first

    assert_text "Alternative thought was successfully destroyed"
  end
end
