from flask import request
from flask_restx import Resource, Api, Namespace, fields
import jwt
import bcrypt
from pymongo import encryption
from bson.objectid import ObjectId


import mongo

from .utils import SECRET_KEY, ALGORITHM

mongodb = mongo.MongoHelper()

User = Namespace(name="user", description="유저 관련 API")

Activity = Namespace(name="activity", description="유저 활동 관련 API")


# 중복확인 함수
def check_duplicate(key, object):
    if mongodb.find_one(query={key: object}, collection_name="user"):
        return {
            "queryStatus": "already exist"
            }, 500


@User.route('/register')
class AuthRegister(Resource):
    """
    (아이디, 닉네임)중복확인, 회원가입, 비밀번호변경, 회원탈퇴
    """

    def get(self):  # 중복확인
        check_id = request.args.get("id")
        check_email = request.args.get("email")
        check_nickname = request.args.get("nickname")
        
        if check_id:
            result = check_duplicate(key="_id", object=check_id)

        if check_email:
            result = check_duplicate(key="information.email", object=check_email)

        if check_nickname:
            result = check_duplicate(key="subInformation.nickname", object=check_nickname)
        
        if not result:
            result = {"queryStatus": "possible"}
        return result
        

    def post(self):  # 회원가입
        """
        회원가입을 완료합니다.
        """
        
        user_info = request.get_json()

        # 중복확인
        if check_duplicate(key="_id", object=user_info["_id"]):
            return{
                "queryStatus": "id already exist"
            }
        if check_duplicate(key="information.email", object=user_info["information"]["email"]):
            return{
                "queryStatus": "email already exist"
            }
        if check_duplicate(key="subInformation.nickname", object=user_info["subInformation"]["nickname"]):
            return{
                "queryStatus": "nickname already exist"
            }
 
        # 비밀번호를 암호화: 암호화할 때는 string이면 안 되고 byte여야 해서 encode
        encrypted_password = bcrypt.hashpw(str(user_info["password"]).encode("utf-8"), bcrypt.gensalt())  

        # 이를 또 UTF-8 방식으로 디코딩하여, str 객체로 데이터 베이스에 저장
        user_info["password"] = encrypted_password.decode("utf-8")  

        # user 의 id로 토큰 생성(고유한 정보가 id 이므로) : string 자료형
        token_encoded = jwt.encode({'_id': user_info["_id"]}, SECRET_KEY, ALGORITHM)  

        try: 
            mongodb.insert_one(user_info, collection_name="user")  # 데이터베이스에 저장
            return {
                'Authorization': str(token_encoded),
                "queryStatus": 'success'
            }, 200
        
        except TypeError:
            return TypeError


    def put(self):
        """
        비밀번호를 변경합니다 
        비밀번호 변경 클릭 -> 아이디 비밀번호 한 번 더 확인 -> 새로운 비밀번호 입력 후 변경
        """
        header = request.headers.get('Authorization')
        token_decoded = jwt.decode(header, SECRET_KEY, ALGORITHM)

        new_password = request.get_json()
        new_encrypted_password = bcrypt.hashpw(str(new_password["password"]).encode("utf-8"), bcrypt.gensalt())
        new_password["password"] = new_encrypted_password.decode('utf-8')  # db 저장시에는 디코드

        result = mongodb.update_one(query={"_id": token_decoded["_id"]}, collection_name="user", modify={"$set": {"password": new_password["password"]}})

        if result.raw_result["n"] == 1:
            return {"queryStatus" : "success"}
        else:
            return {"queryStatus": "password update fail"}, 500

        
    def delete(self):
        """
        회원정보를 삭제합니다(회원탈퇴)
        회원탈퇴 클릭 -> 아이디 비밀번호 한 번 더 확인 -> 회원탈퇴
        """
        header = request.headers.get('Authorization')
        # header 에 token_encoded 를 넣어서 request
        if header is None: 
            return {"queryStatus": "please login"}, 404

        token_decoded = jwt.decode(header, SECRET_KEY, ALGORITHM)  # {'id':실제 id} 딕셔너리형태로 돌려줌

        # # 활동 알수없음으로 바꾸기
        # activity = mongodb.find_one(query={"_id": token_decoded["_id"]}, collection_name="user", projection_key={"activity":True, "_id":False})
        # act_post = activity["activity"]["posts"]
        # act_reply = activity["activity"]["reply"]
        # # 게시글 알 수 없음
        # if act_post:
        #     for i in act_post:
        #         board_type=i[0]
        #         pk = i[1]
        #         mongodb.update_one(query={"_id":pk}, collection_name=board_type, modify={"$set":{"author": None}})
        
        # if act_reply:
        #     for i in act_reply:
        #         board_type=i[0]
        #         pk = i[2]
        #         mongodb.update_one(query={"_id":pk}, collection_name=board_type, modify={"$set":{"reply.author": None}})



        # 탈퇴하기
        result = mongodb.delete_one(query={"_id": token_decoded["_id"]}, collection_name="user")

        if result.raw_result["n"] == 1:
            return{"queryStatus": "success"}
        else :
            return {"queryStatus": "user delete fail"}, 500
    


@User.route('/login')
class AuthLogin(Resource):
    """
    로그인, 회원정보, 회원정보수정
    """
    def post(self):  # 로그인
        """
        입력한 id, password 일치여부를 검사합니다(로그인 시, 회원탈퇴 위한 아이디, 비밀번호 확인 시)
        """
        sign_info = request.get_json()  # 사용자가 로그인 시 입력한 아이디, 비밀번호
        input_password = sign_info["password"]

        user_info = mongodb.find_one(query={"_id": sign_info["_id"]}, collection_name="user")  # 동일한 아이디불러오기
        
        if not user_info:
            # 해당 아이디가 없는 경우
            return {
                "queryStatus": "not exist"
            }, 404

        elif not bcrypt.checkpw(input_password.encode("utf-8"), user_info["password"].encode("utf-8")):
            # 비밀번호가 일치하지 않는 경우
            return {
                "queryStatus": "wrong password"
            }, 500

        else:
            # 비밀번호 일치한 경우
            token_encoded = jwt.encode({'_id': user_info["_id"]}, SECRET_KEY, ALGORITHM)
            return {
                'Authorization': token_encoded, 
                "queryStatus" : 'success'
            }, 200


    def get(self):  # 회원정보조회
        """
        회원정보를 조회합니다.
        """
        header = request.headers.get('Authorization')
        # header 에 token_encoded 를 넣어서 request
        if header is None: 
            return {"queryStatus": "please login"}, 404
        token_decoded = jwt.decode(header, SECRET_KEY, ALGORITHM)  # {'id':실제 id} 딕셔너리형태로 돌려줌
        user_info = mongodb.find_one(query={"_id": token_decoded["_id"]}, collection_name="user")
        user_info["password"] = "비밀번호"
        
        return user_info
    

    def put(self):  # 회원정보수정
        """
        회원정보를 수정합니다
        """
        header = request.headers.get('Authorization')  # 아이디 비밀번호 확인해서 받은 토큰
        token_decoded = jwt.decode(header, SECRET_KEY, ALGORITHM)  # 인코드된 토큰 받아서 디코드함

        new_user_info = request.get_json()
        result = mongodb.update_one(query={"_id": token_decoded["_id"]}, collection_name="user", modify={"$set": new_user_info})

        if result.raw_result["n"] == 1:
            modified_user = mongodb.find_one(query={"_id": token_decoded["_id"]},
                                             collection_name="user")
            modified_user["password"] = "비밀번호"

            return modified_user
        else:
            return {"queryStatus": "infomation update fail"}, 500


class ActivityUpdate():
    def __init__(self, author, field, new_activity_info):
        self.author = author
        self.field = field
        self.new_activity_info = new_activity_info

    def update_activity(self, operator):  # 활동 추가
        """
        사용자 활동 추가하기
        """

        """
        author : 유저 id
        field : 활동 내용 posts, likes, reply, report
        new_activity_info : 구체적인 내용["board_type", "post_id:]
        """   
        
        result = mongodb.update_one(query={"_id": self.author}, collection_name="user", modify={operator: {self.field: self.new_activity_info}})

        if result.raw_result["n"] == 1:
            return {"queryStatus": "success"}
        else:
            return {"queryStatus": "activity update fail"}, 500


@Activity.route("/<string:activity_type>")
class ActivityControl(Resource):
    """
    공감, 스크랩, 댓글, 작성글
    """
    def get(self, activity_type):  # 회원활동 탭에서 보여지는 정보 (게시글 리스트)
        """
        사용자 활동과 관련된 게시글 보여주기
        """
        header = request.headers.get("Authorization")

        if header is None: 
            return {"queryStatus": "please login"}, 404

        token_decoded = jwt.decode(header, SECRET_KEY, ALGORITHM)  # {'id':실제 id} 딕셔너리형태로 돌려줌

        activity_type = activity_type 

        activity_info = mongodb.find_one(query={"_id": token_decoded["_id"]}, collection_name="user")
        # activity_info를 통해서 공감, 스크랩, 댓글, 게시글 별 content_id와 board_type을 얻을 수 있음
        # 이거 가지고 프론트가 get을 요청하거나 백에서 그거 까지 해서 주거나

        specific_activity =  activity_info["activity"][activity_type]
        # 리스트로 이루어진 리스트  "like" : [["board_type", "content_id"], ["board_type", "content_id"]

        post_list = []
        for post in specific_activity:
            try :
                board_type = post[0]+"_board"
                post_id = post[1]

                result = mongodb.find_one(query={"_id": ObjectId(post_id)},collection_name=board_type)
                result["_id"] = str(result["_id"])
                result["date"] = str(result["date"])

                post_list.append(result)  # 제일 뒤로 추가함 => 결국 위치 동일

                post_list.sort(key=lambda x:x["_id"], reverse=True )
            
            except TypeError:
                pass
        
        return {
            "postList" : post_list
        }
