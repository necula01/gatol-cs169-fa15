class QuestionSet
    require 'csv'
    attr_accessor :questions, :setname

    def buildQuestionSet(params=nil)
        @questions = []
    end
    
    #sets up new QuestionSet
    def createSet
        createQuestions(parseCSV)
    end
    
    # turns the array d of array of strings into an array of Question objects
    def createQuestions(arr)
        arr.each do |a| 
            q = Question.new
            @questions.push(q)
        end
    end

    def saveSet
        all = false
        @questions.each do |q|
            all = all && q.save!
        end
        all
    end

    # parses CSV
    # Using the rails' csv library, a line of csv such as 
    #                  1+1?,2,1,3,4,5,6,7,8
    # will be parsed into
    #                  ['1+1?','2','1','3','4','5','6','7','8']
    # and encapsualted in another array containing all the lines of CSV
    def parseCSV
        return []
    end
    
    def getQuestionByIndex(i)
        if (i > 0 && i < @questions.length)
            return @questions[i]
        else
        #Raise Exception here?
        end
    end
    
end
