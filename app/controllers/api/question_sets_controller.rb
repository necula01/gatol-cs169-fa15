class Api::QuestionSetsController < ApplicationController
  before_action :authenticate_with_token!, only: [:show, :edit, :update, :destroy, :import]
  respond_to :json

  # Get all the QuestionSets belonging to a particular User
  # GET /question_sets
  def index
    user = current_user
    #if user.is_trainer?
    @sets = QuestionSet.where(trainer_id: user.id)
    render json: {
      question_sets: qs_json(@sets)
    }
  end

  # GET a certain QuestionSet by id
  # GET /question_sets/1
  def show
    user = current_user
    set = QuestionSet.find(params[:id])
    if set.trainer_id == user.id
      render json: {
        status: 200,
        question_set: qs_json(set)
      }
    else
      render json: {
        status: 401,
        errors: ['trainer does not have access to this question set']
      }
    end
  end

  # GET /question_sets/new
  def new
    @question_set = QuestionSet.new
  end

  #def create
  #  @question_set = QuestionSet.new
  #end


  #POST /question_sets/import
  def import
    user = current_user

    if user.is_trainer?
      f = params[:file]
      q = QuestionSet.new(trainer_id: user.id)
      q.createSet(f)
      if (q.saveSet)
        render json: {
          status: 200,
          question_set: qs_json(q)
        }
      else
        render json: {
          status: 500,
          errors: ['question set could not be saved']
        }
      end
    else
      render json: { errors: ['the user is not a trainer']}, status: 401
    end

  end


  # DELETE /question_sets/1.json
  def destroy
    user = current_user
    question_set = QuestionSet.find(params[:id])
    if !question_set.nil? && question_set.trainer_id == user.id
      question_set.destroy
      render json: {
        status: 200
      }
    elsif question_set.nil?
      render json: {
        status: 400,
        errors: ['question set does not exist']
      }
    else
      render json: {
        status: 401,
        errors: ['trainer does not have access to this question set']
      }
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.

    # Never trust parameters from the scary internet, only allow the white list through.
    def question_set_params
      params[:question_set]
    end


  def qs_json(qs)
    return qs.to_json(:include => :questions) 
  end

end