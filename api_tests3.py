import requests
import json
import inspect
import random

########################
### GLOBAL VARIABLES ###
########################

# SERVER = 'http://localhost:3000'
# SERVER = 'https://calm-garden-9078.herokuapp.com'
SERVER = 'https://gatol.herokuapp.com'
TEST = "test025"
FILEPATH = 'Book1.csv'
TIMEOUT = 200
PASS = 'samplePass'

########################
### HELPER FUNCTIONS ###
########################

def random_email():
    return 'a' + str(random.randint(0,9999999)) + '@hihello.sample'

def create_account(email, username, password, password_confirmation, is_trainer=True):
    payload = {'email':email,
               'username':username,
               'password':password,
               'password_confirmation':password_confirmation}
    if is_trainer:
        return requests.post(SERVER + '/api/trainers', json=payload, timeout=TIMEOUT)
    else:
        return requests.post(SERVER + '/api/students', json=payload, timeout=TIMEOUT)

def verify_account(token, is_trainer=True):
    token = token.encode()
    if is_trainer:
        return requests.get(SERVER + '/api/trainers/' + token + '/confirm', timeout=TIMEOUT)
    else:
        return requests.get(SERVER + '/api/students/' + token + '/confirm', timeout=TIMEOUT)

def login(email, password):
    payload = {'email':email,
               'password':password}
    return requests.post(SERVER + '/api/sessions', json=payload, timeout=TIMEOUT)

def logout(token):
    token = token.encode()
    return requests.delete(SERVER + '/api/sessions/' + str(token), timeout=TIMEOUT)

def delete_account(token, is_trainer=True):
    token = token.encode()
    headers = {'Authorization':token}
    if is_trainer:
        return requests.delete(SERVER + '/api/trainers', headers=headers, timeout=TIMEOUT)
    else:
        return requests.delete(SERVER + '/api/students', headers=headers, timeout=TIMEOUT)

def get_token(idn, is_trainer=True):
    if is_trainer:
        r = requests.get(SERVER + '/api/trainers/' + str(idn), timeout=TIMEOUT)
        if r.status_code != 200:
            raise ValueError("failed to get token " + str(r.status_code))
        return r.json()['auth_token']
    else:
        r = requests.get(SERVER + '/api/students/' + str(idn), timeout=TIMEOUT)
        if r.status_code != 200:
            raise ValueError("failed to get token " + str(r.status_code))
        return r.json()['auth_token']

def upload_csv(token, filepath=FILEPATH):
    token = token.encode()
    headers = {'Authorization':token}
    files = {'file': ('Book1.csv', open(filepath, 'rb'))}
    return requests.post(SERVER + '/api/question_sets/import', headers=headers, files=files)

########################

# quick way to setup an account. returns a login token.
def create_and_login(email, password, is_trainer=True):
    #create account
    r = create_account(email, 'test', password, password, is_trainer)
    if r.status_code != 201:
        raise ValueError("failed to create account " + str(r.status_code))
    idn = r.json()['id']
    #get confirm token
    token = get_token(idn, is_trainer)
    #verify
    r = verify_account(token, is_trainer)
    if r.status_code != 200:
        raise ValueError("verification failed " + str(r.status_code))
    #login
    r = login(email, password)
    if r.status_code != 200:
        raise ValueError("failed to login " + str(r.json()['errors']) + str(r.status_code))
    token = r.json()['auth_token']
    return token








#############
### TESTS ###
#############

### write tests as a method in GatolTest
class GatolTest:

    
    # test 23
    @classmethod
    def test023_trainer_create_game(self):
        try:
            email = random_email()
            decoder = json.JSONDecoder()
        
            # create account
            token = create_and_login(email, PASS)
            token = token.encode()
            
            # upload csv
            upload_csv(token)

            # get question Set id
            headers = {'Authorization':token}
            r = requests.get(SERVER + '/api/question_sets', headers=headers)
            if r.status_code > 299:
                raise ValueError("failed to get set id " + str(r.status_code))

            questionSets = r.json()[u'question_sets']
            questionSets = decoder.decode(questionSets)
            setID = questionSets[0]['id']

            # create game
            payload = {u'game':{u'name':u'testGame1',
                                u'description':u'this is a good game',
                                u'question_set_id':setID,
                                u'game_template_id':0}}
            json_data = json.dumps(payload)
            headers = {'Authorization':token}
            r = requests.post(SERVER + '/api/games', headers=headers, json=payload)
            if r.status_code > 299:
                raise ValueError("failed to create game " + str(r.status_code))
            # get game list
            headers = {'Authorization':token}
            r = requests.get(SERVER + '/api/games', headers=headers)

            if r.status_code > 299:
                raise ValueError("failed to get games " + str(r.status_code))
            
            games = r.json()[u'games']
            gameTitle = games[0][u'name']
            if gameTitle != u'testGame1':
                raise ValueError("game title does not match " + str(r.status_code))
            
            return (True, "")

        except ValueError as e:
            return (False, str(e))



    # test 24
    @classmethod
    def test024_trainer_enrollment(self):
        try:
            email = random_email()
            email2 = random_email()
            email3 = random_email()
            decoder = json.JSONDecoder()
        
            # create account
            token = create_and_login(email, PASS)
            token = token.encode()

            # create account2
            token2 = create_and_login(email2, PASS, False)
            token2 = token2.encode()
            
            # upload csv
            upload_csv(token)

            # get question Set id
            headers = {'Authorization':token}
            r = requests.get(SERVER + '/api/question_sets', headers=headers)
            if r.status_code > 299:
                raise ValueError("failed to get set id " + str(r.status_code))

            questionSets = r.json()[u'question_sets']
            questionSets = decoder.decode(questionSets)
            setID = questionSets[0]['id']

            # create game
            payload = {u'game':{u'name':u'testGame1',
                                u'description':u'this is a good game',
                                u'question_set_id':setID,
                                u'game_template_id':1}}
            json_data = json.dumps(payload)
            headers = {'Authorization':token}
            r = requests.post(SERVER + '/api/games', headers=headers, json=payload)
            if r.status_code > 299:
                raise ValueError("failed to create game " + str(r.status_code) + str(r.json()[u'errors']))
            
            # get game list
            headers = {'Authorization':token}
            r = requests.get(SERVER + '/api/games', headers=headers)
            if r.status_code > 299:
                raise ValueError("failed to get games " + str(r.status_code))

            games = r.json()[u'games']
            
            gameID = games[0][u'id']
            gameTitle = games[0][u'name']
            if gameTitle != u'testGame1':
                raise ValueError("game title does not match " + str(r.status_code))

            print(gameID)
            print(type(gameID))


            # create enrollment
            headers = {'Authorization':token}
            payload = {u'game_enrollment':{u'game_id':gameID,
                                           u'student_email':email3}}
            r = requests.post(SERVER + '/api/game_enrollments', headers=headers, json=payload)
            if r.status_code > 299:
                raise ValueError("failed to create enrollment " + str(r.status_code))


            # student view enrollment
            headers = {'Authorization':token}
            r = requests.get(SERVER + '/api/game_enrollments', headers=headers)
            if r.status_code > 299:
                raise ValueError("failed to view student enrollment0 " + str(r.status_code))


            # create enrollment
            headers = {'Authorization':token}
            payload = {u'game_enrollment':{u'game_id':gameID,
                                           u'student_email':email2}}
            r = requests.post(SERVER + '/api/game_enrollments', headers=headers, json=payload)

            if r.status_code > 299:
                raise ValueError("failed to create enrollment " + str(r.status_code))


            # view enrollment
            headers = {'Authorization':token}
            r = requests.get(SERVER + '/api/game_enrollments/' + str(gameID), headers=headers)
            if r.status_code > 299:
                raise ValueError("failed to view enrollment " + str(r.status_code))


            enrollments = r.json()[u'game_enrollments']
            if len(enrollments) != 2:
                raise ValueError("failed to get enrollments " + str(len(enrollments)))
            entryID = enrollments[0][u'id']


            # student view enrollment
            headers = {'Authorization':token}
            r = requests.get(SERVER + '/api/game_enrollments', headers=headers)
            if r.status_code > 299:
                raise ValueError("failed to view student enrollment " + str(r.status_code))




            # delete enrollment
            headers = {'Authorization':token}
            r = requests.delete(SERVER + '/api/game_enrollments/' + str(entryID), headers=headers)
            if r.status_code > 299:
                raise ValueError("failed to create enrollment " + str(r.status_code))


            # view enrollment
            headers = {'Authorization':token}
            r = requests.get(SERVER + '/api/game_enrollments/' + str(gameID), headers=headers)
            if r.status_code > 299:
                raise ValueError("failed to create enrollment " + str(r.status_code))

            enrollments = r.json()[u'game_enrollments']
            if len(enrollments) != 1:
                raise ValueError("failed to get enrollments " + str(len(enrollments)))
 



            
            return (True, "")

        except ValueError as e:
            return (False, str(e))


    # test 25
    @classmethod
    def test025_game_play_and_stat(self):
        try:
            trainer_email = random_email()
            student_email = random_email()
            decoder = json.JSONDecoder()
        
            # create trainer account
            token = create_and_login(trainer_email, PASS)
            token = token.encode()

            # create account2
            token2 = create_and_login(student_email, PASS, False)
            token2 = token2.encode()

            # upload csv
            upload_csv(token)

            # get question Set id
            headers = {'Authorization':token}
            r = requests.get(SERVER + '/api/question_sets', headers=headers)
            if r.status_code > 299:
                raise ValueError("failed to get set id " + str(r.status_code))

            questionSets = r.json()[u'question_sets']
            questionSets = decoder.decode(questionSets)
            setID = questionSets[0]['id']

            # create game
            payload = {u'game':{u'name':u'testGame1',
                                u'description':u'this is a good game',
                                u'question_set_id':setID,
                                u'game_template_id':1}}
            json_data = json.dumps(payload)
            headers = {'Authorization':token}
            r = requests.post(SERVER + '/api/games', headers=headers, json=payload)
            if r.status_code > 299:
                raise ValueError("failed to create game " + str(r.status_code) + str(r.json()[u'errors']))


            # get game list
            headers = {'Authorization':token}
            r = requests.get(SERVER + '/api/games', headers=headers)
            if r.status_code > 299:
                raise ValueError("failed to get games " + str(r.status_code))

            games = r.json()[u'games']
            
            gameID = games[0][u'id']
            gameTitle = games[0][u'name']
            if gameTitle != u'testGame1':
                raise ValueError("game title does not match " + str(r.status_code))

            print(gameID)
            print(type(gameID))


            # create enrollment
            headers = {'Authorization':token}
            payload = {u'game_enrollment':{u'game_id':gameID,
                                           u'student_email':student_email}}
            r = requests.post(SERVER + '/api/game_enrollments', headers=headers, json=payload)
            if r.status_code > 299:
                raise ValueError("failed to create enrollment " + str(r.status_code))


            # student get information about the game            
            headers = {'Authorization':token2}
            r = requests.get(SERVER + '/api/games/' + str(gameID), headers=headers)
            if r.status_code > 299:
                raise ValueError("failed to get information about the game " + str(r.status_code))
            print(r.json())
            print(r.json()[u'game'])
            print(type(r.json()[u'game']))


            # student initiate a game
            headers = {'Authorization':token2}
            payload = {'game_id':gameID}
            r = requests.post(SERVER + '/api/game_instances', headers=headers, json=payload)
            if r.status_code > 299:
                raise ValueError("failed to post game_instance " + str(r.status_code))

            print(r.json())
            print(r.json()[u'game_instance_id'])
            game_instance_id = str(r.json()[u'game_instance_id'])
            

            # play game
            headers = {'Authorization':token2}
            payload = {'score':10,
                       'lastQuestion':2}
            r = requests.put(SERVER + '/api/game_instances/' + game_instance_id, headers=headers, json=payload)
            if r.status_code > 299:
                raise ValueError("failed to put game_instances " + str(r.status_code))


            # play another game
            headers = {'Authorization':token2}
            payload = {'score':17,
                       'lastQuestion':4}
            r = requests.put(SERVER + '/api/game_instances/' + game_instance_id, headers=headers, json=payload)
            if r.status_code > 299:
                raise ValueError("failed to put game_instances " + str(r.status_code))
            


            # trainer get stats from student
            headers = {'Authorization':token}
            payload = {'student_email':student_email,
                       'game_id':gameID}
            r = requests.get(SERVER + '/api/game_instances/player?'
                             + 'student_email=' + payload['student_email']
                             + '&game_id=' + str(payload['game_id']), headers = headers)
            if r.status_code > 299:
                raise ValueError("failed to get student stats(trainer) "  + str(r.status_code))
            print(r.json())
            print(r.json()[u'history'])
            print(type(r.json()[u'history']))
            

            # student view his own history
            headers = {'Authorization':token}
            payload = {'game_id':gameID}
            r = requests.get(SERVER + '/api/game_instances/stats?'
                             + '&game_id=' + str(payload['game_id']), headers = headers)
            if r.status_code > 299:
                raise ValueError("failed to get student stats(student) " + str(r.status_code))
            print(r.json())
            print(r.json()[u'history'])
            print(type(r.json()[u'history']))
            

   
            return (True, "")

        except ValueError as e:
            return (False, str(e))



### DO NOT CHANGE UNDERTHIS LINE ###
if __name__ == '__main__':
    print("Gatol API tests")
    print("***")
    test_list = inspect.getmembers(GatolTest, predicate=inspect.ismethod)

    if TEST != "":
        new_list = []
        for test in test_list:
            if test[0].startswith(TEST):
                new_list.append(test)
        test_list = new_list
        
    index = 0
    num_pass = 0
    for test in test_list:
        index += 1
        result = test[1]()
        if result[0]:
            print 'PASSED {1}'.format(index, test[0])
            num_pass += 1
        else:
            print 'FAILED {1} ::: {2}'.format(index, test[0], result[1])
    print("***")
    print(str(num_pass) + "/" + str(len(test_list)) + " tests passed")
        
                         
