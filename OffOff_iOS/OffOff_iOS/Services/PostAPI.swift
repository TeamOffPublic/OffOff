//
//  PostAPI.swift
//  OffOff_iOS
//
//  Created by Lee Nam Jun on 2021/07/27.
//

import Foundation
import Moya

// 게시글, 게시글 목록과 관련된 API

enum PostAPI {
    case getPost(content_id: String, board_type: String)
    case makePost(post: WritingPost)
    case deletePost(post: DeletingPost)
    case likePost(post: PostActivity)
    case modifyPost(post: WritingPost)
    case getOriginalImages(postId: String, boardType: String)
}

extension PostAPI: TargetType, AccessTokenAuthorizable {
    var baseURL: URL {
        return URL(string: Constants.API_SOURCE)!
    }
    
    var path: String {
        switch self {
        case .getPost(_, _):
            return "/post"
        case .makePost(_):
            return "/post"
        case .deletePost(_):
            return "/post"
        case .likePost(_):
            return "/post"
        case .modifyPost(_):
            return "/post"
        case .getOriginalImages(_, _):
            return "/post"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getPost(_, _):
            return .get
        case .makePost(_):
            return .post
        case .deletePost(_):
            return .delete
        case .likePost(_):
            return .put
        case .modifyPost(_):
            return .put
        case .getOriginalImages(_, _):
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .getPost(let content_id, let board_type):
            return .requestParameters(parameters: ["postId": content_id, "boardType": board_type], encoding: URLEncoding.default)
        case .makePost(let post):
            return .requestJSONEncodable(post)
        case .deletePost(let post):
            return .requestJSONEncodable(post)
        case .likePost(let post):
            return .requestJSONEncodable(post)
        case .modifyPost(let post):
            return .requestJSONEncodable(post)
        case .getOriginalImages(let postId, let boardType):
            return .requestParameters(parameters: ["postId": postId, "boardType": boardType], encoding: URLEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var authorizationType: AuthorizationType? {
        .bearer
    }
}

struct DeletingPost: Codable {
    var _id: String
    var boardType: String
    var author: String
}
