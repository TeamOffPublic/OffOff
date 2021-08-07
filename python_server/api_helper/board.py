from flask import request
from flask_restx import Resource, Namespace
from bson.objectid import ObjectId
from datetime import datetime, timedelta

import mongo

mongodb = mongo.MongoHelper()


BoardList = Namespace(
    name="boardlist",
    description="게시판목록을 불러오는 API")

PostList = Namespace(
    name="postlist",
    description="게시글목록을 불러오는 API")



@BoardList.route("")
# 사용자가 커뮤니티 탭을 클릭하는 경우
class BoardListControl(Resource):

    def get(self):
        """
        DB > board_list 컬랙션에서 게시판을 조회합니다
        """
        """
        {
            "_id": 
            "boardType": "free"
            "name": "자유게시판"
            "icon": string(url)
            "newPost": True
        }
        """
        cursor = mongodb.find(collection_name="board_list", projection_key={"_id": 0})
        
        board_list = []
        for board in cursor:
            board_list.append(board)
        
        for board in board_list:
            board_type = board["boardType"]+"_board"
            access_on = datetime.now()
            standard = access_on - timedelta(hours=3)
            if mongodb.aggregate(collection_name=board_type, pipeline={"$match": {"date": {"$gte":standard}}}):
                board["newPost"] = True
            else:
                board["newPost"] = False
 
        return {
            "boardList": board_list
        }
    
    
    def delete(self):  # 게시판 목록 삭제
        """특정 게시판 정보를 삭제합니다."""
        board_info = request.get_json()
        board_type = board_info["boardType"]

        result = mongodb.delete_one(query={"boardType": board_type}, collection_name="board_list")

        if result.raw_result["n"] == 1:
            return {"query_status": "해당 게시판을 삭제했습니다."}
        else:
            return {"query_status": "게시판 삭제를 실패했습니다."}, 500


    def post(self):  # 게시판 목록 등록
        """특정 게시판 정보를 등록합니다."""
        board_info = request.get_json()

        mongodb.insert_one(data=board_info, collection_name="board_list")

        return {"query_status": "게시판을 등록했습니다"}


@PostList.route("/<string:board_type>")
# 사용자가 특정 게시판을 클릭하는 경우
class PostListControl(Resource):

    def get(self, board_type):
        """
        DB > 해당 게시판의 컬랙션(free_board)에서 게시글을 조회합니다
        """
        try:

            board_type = board_type + "_board"
            page_size = int(request.args.get("pageSize", default=20))
            last_post_id = request.args.get("lastPostId", default="")

            if not last_post_id:  # 게시판에 처음 들어간 경우
                cursor = mongodb.find(collection_name=board_type).sort([("_id", -1)]).limit(page_size)
            else:  # 스크롤 하는 경우
                last_content_id = ObjectId(last_post_id)
                cursor = mongodb.find(query={'_id': {'$lt': last_content_id}}, collection_name=board_type).sort(
                    [("_id", -1)]).limit(page_size)  # 고정해도 되나?
 

            post_list = []
            for post in cursor:
                post["_id"] = str(post["_id"])
                post_list.append(post)

            last_post_id = post_list[-1]["_id"]

            
            if board_type is "hot_board":  # 인기게시판인 경우
                hot_post_list = []
                for temp_post in post_list:
                    post_id = temp_post["_id"]
                    board_type = temp_post["boardType"]

                    post = mongodb.find_one(query={"_id": ObjectId(post_id)}, collection_name=board_type)
                    post["_id"] = str(post["_id"])

                    hot_post_list.append(post)
                
                return {
                    "lastPostId": last_post_id,
                    "postList": hot_post_list
                }
            
            else:
                return {
                    "lastPostId": last_post_id,
                    "postList": post_list
                }

                 
        except IndexError:  # 더 이상 없는 경우
            return {
                "lastPostId": None,
                "postList": None
            }

