class GameInstance < ActiveRecord::Base
	self.table_name = "training_history"
	belongs_to :student
	belongs_to :game

	validates_presence_of :student
	validates_presence_of :game

	after_initialize do |g|
		@qcount = nil
    end


    #Returns true if update succeeds and false if not
    #Will raise ArgumentError if lastQuestion is invalid
    def update(score, lastQuestion)
    	s = score
    	q = lastQuestion
    	if score.is_a? String 
    		s = score.to_i
    	end

    	if lastQuestion.is_a? String
    		q = lastQuestion.to_i
    	end

    	if self.active
    		if @qcount.nil?
				@qcount = self.game.question_set.getNumberQuestions
			end
    		if q > @qcount
    			raise ArgumentError, 'invalid lastQuestion: exceeds number of questions'
    		elsif q < self.lastQuestion
    			raise ArgumentError, 'invalid lastQuestion: smaller than last stored question number'
    		else
    			self.score = s
    			self.lastQuestion = q
    			checkGameOngoing
    			return self.save!
    		end
    	end
    	return self.active
    end

    def checkGameOngoing
		if self.active && self.lastQuestion == @qcount
			self.active = false
		end
	end

	##############################
	### QUERY METHODS ############
	##############################

    def self.getActiveGames(sid)
    	GameInstance.where(student_id: sid, active: true)
    end


	#Gets (score, date) tuples for a certain game and orders by student_id
	#If a student is specified, only scores for that student are returned
	def self.getAllScoresForGame(gid, sid=nil)
		if sid.nil?
			GameInstance.where(game_id: gid, active: false).order(student_id: :asc, score: :desc)
		else
			GameInstance.where(student_id: sid, game_id: gid, active: false).order(score: :desc)
		end
	end

	def self.getAllScoresForStudent(sid)
		GameInstance.where(student_id: sid, active: false).order(score: :desc)
	end

	def self.getTop(gid, x)
		GameInstance.joins(:student).select(:id, :game_id, 'students.email as email', :score).where(game_id: gid, active: false).order(score: :desc).limit(x)
	end

	def self.getTop10(gid)
		self.getTop(gid, 10)
	end

	def self.getAllGameSummaries(tid)
		tgames = Game.where(trainer_id: tid)
		s = {}
		for g in tgames
			s[g.id] = GameInstance.getTop(g.id, 5)	
		end

		return s
	end

	def self.getPlayerSummaries(gid)
		GameInstance.select("max(score) as highest_score", "avg(score) as avg_score", :student_id).where(game_id: gid, active: false).group(:student_id).order(student_id: :asc)
	end
end
