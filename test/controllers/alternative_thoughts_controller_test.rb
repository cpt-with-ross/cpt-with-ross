require "test_helper"

class AlternativeThoughtsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alternative_thought = alternative_thoughts(:one)
  end

  test "should get index" do
    get alternative_thoughts_url
    assert_response :success
  end

  test "should get new" do
    get new_alternative_thought_url
    assert_response :success
  end

  test "should create alternative_thought" do
    assert_difference("AlternativeThought.count") do
      post alternative_thoughts_url, params: { alternative_thought: { alternative_thought: @alternative_thought.alternative_thought, belief_rating: @alternative_thought.belief_rating, evidence_against: @alternative_thought.evidence_against, evidence_for: @alternative_thought.evidence_for, stuck_point_id: @alternative_thought.stuck_point_id } }
    end

    assert_redirected_to alternative_thought_url(AlternativeThought.last)
  end

  test "should show alternative_thought" do
    get alternative_thought_url(@alternative_thought)
    assert_response :success
  end

  test "should get edit" do
    get edit_alternative_thought_url(@alternative_thought)
    assert_response :success
  end

  test "should update alternative_thought" do
    patch alternative_thought_url(@alternative_thought), params: { alternative_thought: { alternative_thought: @alternative_thought.alternative_thought, belief_rating: @alternative_thought.belief_rating, evidence_against: @alternative_thought.evidence_against, evidence_for: @alternative_thought.evidence_for, stuck_point_id: @alternative_thought.stuck_point_id } }
    assert_redirected_to alternative_thought_url(@alternative_thought)
  end

  test "should destroy alternative_thought" do
    assert_difference("AlternativeThought.count", -1) do
      delete alternative_thought_url(@alternative_thought)
    end

    assert_redirected_to alternative_thoughts_url
  end
end
