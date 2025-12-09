# frozen_string_literal: true

# =============================================================================
# Baseline - Personal Trauma Baseline Assessment
# =============================================================================
#
# A Baseline is an early CPT exercise where users complete the PTSD checklist
# and write about how the traumatic event has affected their lives and beliefs.
# It covers impact on five key areas:
#
# 1. Safety - Beliefs about personal safety and danger
# 2. Trust - Ability to trust self and others
# 3. Power/Control - Sense of agency and control
# 4. Esteem - Self-worth and view of others
# 5. Intimacy - Ability to be close to others
#
# The baseline helps users articulate their experience and often reveals
# stuck points that become the focus of later therapy work.
#
# Note: Baselines are 1:1 with IndexEvents and auto-created via callback.
#
class Baseline < ApplicationRecord
  belongs_to :index_event, inverse_of: :baseline

  validates :index_event, presence: true

  # Experience type options for how the event was experienced
  EXPERIENCE_TYPES = {
    'direct' => 'It happened to me directly.',
    'witnessed' => 'I witnessed it.',
    'learned' => 'I learned about it happening to a close family member or close friend.',
    'job_exposure' => 'I was repeatedly exposed to details about it as part of my job ' \
                      '(for example, paramedic, police, military, or other first responder).',
    'other' => 'Other'
  }.freeze

  # Death cause type options
  DEATH_CAUSE_TYPES = {
    'accident_violence' => 'Accident or violence',
    'natural_causes' => 'Natural causes',
    'not_applicable' => 'Not applicable (the event did not involve the death of a close family member or close friend)'
  }.freeze

  # PCL-5 scale labels
  PCL_SCALE = {
    0 => 'Not at all',
    1 => 'A little bit',
    2 => 'Moderately',
    3 => 'Quite a bit',
    4 => 'Extremely'
  }.freeze

  # PCL-5 questions with their attribute names
  # rubocop:disable Layout/LineLength
  PCL_QUESTIONS = {
    pcl_disturbing_memories: 'Repeated, disturbing, and unwanted memories of the stressful experience?',
    pcl_disturbing_dreams: 'Repeated, disturbing dreams of the stressful experience?',
    pcl_flashbacks: 'Suddenly feeling or acting as if the stressful experience were actually happening again (as if you were actually back there reliving it)?',
    pcl_upset_reminders: 'Feeling very upset when something reminded you of the stressful experience?',
    pcl_physical_reactions: 'Having strong physical reactions when something reminded you of the stressful experience (for example, heart pounding, trouble breathing, sweating)?',
    pcl_avoiding_memories: 'Avoiding memories, thoughts, or feelings related to the stressful experience?',
    pcl_avoiding_reminders: 'Avoiding external reminders of the stressful experience (for example, people, places, conversations, activities, objects, or situations)?',
    pcl_trouble_remembering: 'Trouble remembering important parts of the stressful experience (not due to head injury or substances)?',
    pcl_negative_beliefs: 'Having strong negative beliefs about yourself, other people, or the world (for example, having thoughts such as I am bad, There is something seriously wrong with me, No one can be trusted, or The world is completely dangerous)?',
    pcl_blaming: "Blaming yourself or someone else (who didn't intend the outcome) for the stressful experience or what happened after it?",
    pcl_negative_feelings: 'Having strong negative feelings, such as fear, horror, anger, guilt, or shame?',
    pcl_loss_of_interest: 'Loss of interest in activities that you used to enjoy?',
    pcl_feeling_distant: 'Feeling distant or cut off from other people?',
    pcl_trouble_positive_feelings: 'Trouble experiencing positive feelings (for example, being unable to feel happiness or have loving feelings for people close to you)?',
    pcl_irritable_behavior: 'Irritable behavior, angry outbursts, or acting aggressively?',
    pcl_risky_behavior: 'Taking too many risks or doing things that could cause you harm?',
    pcl_super_alert: 'Being "super alert" or watchful or on guard?',
    pcl_jumpy: 'Feeling jumpy or easily startled?',
    pcl_difficulty_concentrating: 'Having difficulty concentrating?',
    pcl_sleep_trouble: 'Trouble falling or staying asleep?'
  }.freeze
  # rubocop:enable Layout/LineLength

  # Calculate total PCL-5 score (0-80 range)
  def pcl_total_score
    PCL_QUESTIONS.keys.sum { |attr| send(attr) || 0 }
  end

  # Check if all PCL questions have been answered
  def pcl_complete?
    PCL_QUESTIONS.keys.all? { |attr| send(attr).present? }
  end
end
