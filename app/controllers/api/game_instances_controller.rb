class Api::GameInstancesController < ApplicationController
  before_action :authenticate_with_token!, only: [:show, :update, :destroy]
  respond_to :json


  # GET /game_instances
  # For students, this is the same as get_stats_all
  # For trainers, this returns 
  def index
    user = current_user
    if user.is_trainer?
      get_stats_all_trainer
    else
      get_stats_all_student
    end
  end

  # GET /game_instances/1
  def show
    user = current_user
    game_instance = GameInstance.find_by_id(params[:id])
    if !game_instance.nil? && game_instance.student_id == user.id
      render json: {
        status: 200,
        game_instance: game_instance
      }
    elsif game_instance.nil?
      render json: {
        status: 400,
        errors: ['game instance does not exist']
      }  
    else
      render json: {
        status: 401,
        errors: ['user does not have access to this game instance']
      }
    end
  end

  # POST /game_instances
  def create
    user = current_user
    if user.is_trainer?
      game = Game.find_by_id(params[:game_id])
      render json: {
        game_instance_id: 0,
        game_description: game.description,
        question_set_id: game.question_set_id,
        template_id: game.game_template_id
      }, status: 200
      return
    end

    game_instance = GameInstance.new()
    game_instance.game_id = params[:game_id]
    game_instance.student_id = user.id
    game_instance.score = 0
    game_instance.lastQuestion = 0

    game = Game.find_by_id(params[:game_id])

    if game_instance.save
      render json: {
          game_instance_id: game_instance.id,
          game_description: game.description,
          question_set_id: game.question_set_id,
          template_id: game.game_template_id
        }, status: 200
    else
      render json: {}, status: 401
    end
  end

  # PATCH/PUT /game_instances/1
  def update
    user = current_user
    if user.is_trainer?
      render json: {}, status: 200
      return
    end
    newScore = params[:score]
    q = params[:lastQuestion]
    game_instance = GameInstance.find_by_id(params[:id])
    if !game_instance.nil? && game_instance.student_id == user.id
      begin 
        if game_instance.update(newScore, q) 
          render json: {
          }, status: 200
        end
      rescue ArgumentError => e
        render json: {
          errors: ['update could not be completed', e.message]
        }, status: 400

      rescue ActiveRecord::RecordInvalid => e
        render json: {
          errors: ['update could not be completed', 
                  'invalid record', 
                    e.message]
        }, status: 400
      rescue StandardError => e
        render json: {
          errors: ['update could not be completed', e.message]
        }, status: 500
      end
    elsif game_instance.nil?
      render json: {
        errors: ['game instance does not exist']
      }, status: 400 
    else
      render json: {
        errors: ['user does not have access to this game instance']
      }, status: 401
    end
  end

  # DELETE /game_instances/1
  def destroy
    user = current_user
    game = GameInstance.find_by_id(params[:id])
    if !game.nil? && game.student_id == user.id
      game.destroy
      render json: {}, status: 200
    elsif game.nil?
      render json: {
        errors: ['game instance does not exist']
      }, status: 400
    else
      render json: {
        errors: ['student does not have access to this game instance']
      }, status: 401
    end
  end

  def get_leaderboard
    user = current_user
    gid = params[:game_id]
    leaderboard = GameInstance.getTop10(gid)

    render json: {
      ranking: student_friendly_json(leaderboard)
    }, status: 200
  end


  # View Games (Student): views all games that student is playing
  def get_active
    user = current_user
    active = GameInstance.where(student_id: user.id, active: true)
    render json: {
      games: active
    }, status: 200
  end

  # View Player Statistics for all games (Student)
  def get_stats_all_student
    user = current_user
    all = GameInstance.getAllScoresForStudent(user.id)
    render json: {
      history: all
    }
  end

  # View Player Statistics for specific game (Student)
  def get_stats_game
    user = current_user
    gid = params[:game_id]
    stats = GameInstance.getAllScoresForGame(gid, user.id)
    render json: {
      history: stats
    }
  end

  # View Game Statistics for specific player on specific game (Trainer)
  def get_stats_player
    user = current_user
    pemail = params[:student_email]
    gid = params[:game_id]
    g = Game.find_by_id(gid)
    if g.nil?
      render json: {
        errors: ['no game exists for this game id']
      }, status: 404
      return
    end

    if user.is_trainer? && g.trainer_id == user.id
      pid = Student.find_by email: pemail
      if pid.nil?
        render json: {
          errors: ['no student found for given email']
        }, status: 404
      #elsif student is enrolled in this game
      else
        stats = GameInstance.getAllScoresForGame(gid, pid)
        render json: {
          history: stats
        }, status: 200
      end
    elsif user.is_trainer?
        render json: {
          errors: ['trainer does not have access to this game data']
        }, status: 401
    elsif email == user.email
      get_stats_game
    else
      render json: {
          errors: ['student does not have access to player data']
        }, status: 401
    end
  end

  # View Game Summary for specific game (Trainer)
  # Returns
  def get_stats_summary
    user = current_user
    gid = params[:game_id]
    render json: {
      ranking: GameInstance.getTop(gid, 15),
      player_summaries: GameInstance.getPlayerSummaries(gid)
    }
  end

  def get_stats_all_trainer
    user = current_user
    gid = params[:game_id]
    #ranking = GameInstance.
    render json: {
      ranking: GameInstance.getAllGameSummaries(user.id)
      #player_summaries: GameInstance.getPlayerSummaries(gid)
    }
  end

  private

    def student_friendly_json(i)
      return i.as_json(only: [:score, :email])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_game_instance
      @game_instance = GameInstance.find_by_id(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_instance_params
      params[:game_instance]
    end
end
