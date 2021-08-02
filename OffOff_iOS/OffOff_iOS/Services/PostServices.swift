//
//  PostServices.swift
//  OffOff_iOS
//
//  Created by Lee Nam Jun on 2021/07/12.
//

import Foundation
import Moya

public class PostServices {
    static let provider = MoyaProvider<PostAPI>()
    
    static func fetchPostList(board_type: String, completion: @escaping (_ postList: PostList) -> Void) {
        PostServices.provider.request(.getPostList(board_type)) { (result) in
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusCodes()
                    let decoder = JSONDecoder()
                    let postList = try filteredResponse.map(PostList.self, using: decoder)
                    completion(postList)
                } catch let error {
                    print(error.localizedDescription)
                }
            case let .failure(error):
                print("request failed: \(error.errorDescription)")
            }
        }
    }
    
    static func fetchPost(content_id: String, board_type: String, completion: @escaping (_ post: Post) -> Void) {
        PostServices.provider.request(.getPost(content_id: content_id, board_type: board_type)) { (result) in
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusCodes()
                    let decoder = JSONDecoder()
                    let post = try filteredResponse.map(Post.self, using: decoder)
                    completion(post)
                } catch let error {
                    print(error.localizedDescription)
                }
            case let .failure(error):
                print("request failed: \(error.errorDescription)")
            }
        }
    }
}
