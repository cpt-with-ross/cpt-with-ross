require "test_helper"

class AbcWorksheetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @abc_worksheet = abc_worksheets(:one)
  end

  test "should get index" do
    get abc_worksheets_url
    assert_response :success
  end

  test "should get new" do
    get new_abc_worksheet_url
    assert_response :success
  end

  test "should create abc_worksheet" do
    assert_difference("AbcWorksheet.count") do
      post abc_worksheets_url, params: { abc_worksheet: { activating_event: @abc_worksheet.activating_event, consequence_behaviour: @abc_worksheet.consequence_behaviour, consequence_feeling: @abc_worksheet.consequence_feeling, feeling_intensity: @abc_worksheet.feeling_intensity, stuck_point_id: @abc_worksheet.stuck_point_id } }
    end

    assert_redirected_to abc_worksheet_url(AbcWorksheet.last)
  end

  test "should show abc_worksheet" do
    get abc_worksheet_url(@abc_worksheet)
    assert_response :success
  end

  test "should get edit" do
    get edit_abc_worksheet_url(@abc_worksheet)
    assert_response :success
  end

  test "should update abc_worksheet" do
    patch abc_worksheet_url(@abc_worksheet), params: { abc_worksheet: { activating_event: @abc_worksheet.activating_event, consequence_behaviour: @abc_worksheet.consequence_behaviour, consequence_feeling: @abc_worksheet.consequence_feeling, feeling_intensity: @abc_worksheet.feeling_intensity, stuck_point_id: @abc_worksheet.stuck_point_id } }
    assert_redirected_to abc_worksheet_url(@abc_worksheet)
  end

  test "should destroy abc_worksheet" do
    assert_difference("AbcWorksheet.count", -1) do
      delete abc_worksheet_url(@abc_worksheet)
    end

    assert_redirected_to abc_worksheets_url
  end
end
