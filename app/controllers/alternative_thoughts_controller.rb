class AlternativeThoughtsController < ApplicationController
  include InlineFormRenderable
  include StuckPointChildResource

  before_action :set_alternative_thought, only: %i[show edit update destroy]

  def show
  end

  def new
    @alternative_thought = @stuck_point.alternative_thoughts.build
    render_inline_form @alternative_thought,
                       url: stuck_point_alternative_thoughts_path(@stuck_point),
                       placeholder: 'Alternative Thought Title...',
                       frame_id: "new_at_frame_#{@stuck_point.id}",
                       attribute_name: :title
  end

  def edit
    if turbo_frame_request_id == 'main_content'
      render :edit
    else
      render_inline_form @alternative_thought,
                         url: alternative_thought_path(@alternative_thought),
                         placeholder: 'Alternative Thought Title...',
                         frame_id: dom_id(@alternative_thought, :title_frame),
                         attribute_name: :title
    end
  end

  def create
    @alternative_thought = @stuck_point.alternative_thoughts.build(alternative_thought_params)

    if @alternative_thought.save
      respond_with_turbo_or_redirect do
        render turbo_stream: [
          turbo_stream.append("at_list_#{@stuck_point.id}",
                              partial: 'shared/file_sidebar_item',
                              locals: { item: @alternative_thought }),
          turbo_stream.update("new_at_frame_#{@stuck_point.id}", ''),
          turbo_stream.update('main_content',
                              partial: 'alternative_thoughts/show_content',
                              locals: { alternative_thought: @alternative_thought,
                                        stuck_point: @stuck_point })
        ]
      end
    else
      render_inline_form @alternative_thought,
                         url: stuck_point_alternative_thoughts_path(@stuck_point),
                         placeholder: 'Alternative Thought Title...',
                         frame_id: "new_at_frame_#{@stuck_point.id}",
                         attribute_name: :title,
                         status: :unprocessable_content
    end
  end

  def update
    if @alternative_thought.update(alternative_thought_params)
      respond_with_turbo_or_redirect do
        render turbo_stream: [
          turbo_stream.replace(
            dom_id(@alternative_thought, :title_frame),
            partial: 'shared/file_sidebar_title',
            locals: { item: @alternative_thought }
          ),
          turbo_stream.update(
            'main_content',
            partial: 'alternative_thoughts/show_content',
            locals: { alternative_thought: @alternative_thought, stuck_point: @stuck_point }
          )
        ]
      end
    else
      render_inline_form @alternative_thought,
                         url: alternative_thought_path(@alternative_thought),
                         placeholder: 'Alternative Thought Title...',
                         frame_id: dom_id(@alternative_thought, :title_frame),
                         attribute_name: :title,
                         status: :unprocessable_content
    end
  end

  def destroy
    destroy_with_fallback(@alternative_thought, alternative_thought_path(@alternative_thought))
  end

  private

  def set_alternative_thought
    @alternative_thought = AlternativeThought.joins(stuck_point: { index_event: :user })
                                             .where(users: { id: current_user.id })
                                             .find(params[:id])
    @stuck_point = @alternative_thought.stuck_point
  end

  def alternative_thought_params
    params.require(:alternative_thought).permit(:title, :unbalanced_thought, :balanced_thought)
  end
end
