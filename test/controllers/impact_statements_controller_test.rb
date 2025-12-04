require "test_helper"

class ImpactStatementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @impact_statement = impact_statements(:one)
  end

  test "should get index" do
    get impact_statements_url
    assert_response :success
  end

  test "should get new" do
    get new_impact_statement_url
    assert_response :success
  end

  test "should create impact_statement" do
    assert_difference("ImpactStatement.count") do
      post impact_statements_url, params: { impact_statement: { content: @impact_statement.content, trauma_id: @impact_statement.trauma_id } }
    end

    assert_redirected_to impact_statement_url(ImpactStatement.last)
  end

  test "should show impact_statement" do
    get impact_statement_url(@impact_statement)
    assert_response :success
  end

  test "should get edit" do
    get edit_impact_statement_url(@impact_statement)
    assert_response :success
  end

  test "should update impact_statement" do
    patch impact_statement_url(@impact_statement), params: { impact_statement: { content: @impact_statement.content, trauma_id: @impact_statement.trauma_id } }
    assert_redirected_to impact_statement_url(@impact_statement)
  end

  test "should destroy impact_statement" do
    assert_difference("ImpactStatement.count", -1) do
      delete impact_statement_url(@impact_statement)
    end

    assert_redirected_to impact_statements_url
  end
end
