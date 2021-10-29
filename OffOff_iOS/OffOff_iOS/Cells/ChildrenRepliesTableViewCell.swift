//
//  ChildrenRepliesTableViewCell.swift
//  OffOff_iOS
//
//  Created by Lee Nam Jun on 2021/10/19.
//

import UIKit
import RxSwift
import RxCocoa

class ChildrenRepliesTableViewCell: UITableViewCell {
    static let identifier = "ChildrenRepliesTableViewCell"

    var reply = BehaviorSubject<Reply?>(value: nil)
    var disposeBag = DisposeBag()
    var alertDisposeBag = DisposeBag()
    
    var boardTpye: String?
    var activityAlert: ((_ title: String) -> Void)?
    var dismissAlert: ((_ animated: Bool) -> Void)?
    var presentMenuAlert: ((_ alert: UIAlertController) -> Void)?
    
    var replies = BehaviorSubject<[Reply]?>(value: nil)
    
    var profileImageView = UIImageView().then {
        $0.backgroundColor = .lightGray
    }
    
    var nicknameLabel = UILabel().then {
        $0.backgroundColor = .white
    }
    
    var dateLabel = UILabel().then {
        $0.backgroundColor = .white
    }
    
    var contentTextView = UITextView().then {
        $0.backgroundColor = .white
        $0.isScrollEnabled = false
        $0.sizeToFit()
        $0.isUserInteractionEnabled = false
    }
    
    var likeButton = UIButton().then {
        $0.setTitleColor(.black, for: .normal)
        $0.setTitle("0", for: .normal)
        $0.titleLabel?.textAlignment = .right
        $0.setImage(.ICON_LIKES_RED, for: .normal)
        $0.imageView?.contentMode = .scaleAspectFit
        $0.titleLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        $0.titleLabel?.adjustsFontForContentSizeCategory = true
        $0.contentHorizontalAlignment = .left
    }
    
    var menubutton = UIButton().then {
        $0.setTitle("...", for: .normal)
        $0.setTitleColor(.black, for: .normal)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(profileImageView)
        self.contentView.addSubview(nicknameLabel)
        self.contentView.addSubview(dateLabel)
        self.contentView.addSubview(contentTextView)
        self.contentView.addSubview(likeButton)
        self.contentView.addSubview(menubutton)
        bindData()
        makeView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bindData()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bindData()
    }

    private func makeView() {
        profileImageView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8.0)
            $0.left.equalToSuperview().inset(30)
            $0.width.height.equalTo(20.0)
        }
        nicknameLabel.snp.makeConstraints {
            $0.left.equalTo(profileImageView.snp.right).offset(8.0)
            $0.centerY.equalTo(profileImageView)
        }
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.bottom).offset(8.0)
            $0.left.equalTo(profileImageView)
            $0.right.equalToSuperview()
        }
        contentTextView.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(8.0)
            $0.left.equalTo(dateLabel)
            $0.right.equalToSuperview().inset(8.0)
        }
        likeButton.snp.makeConstraints {
            $0.top.equalTo(contentTextView.snp.bottom).offset(8.0)
            $0.left.equalTo(contentTextView)
            //            $0.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        menubutton.snp.makeConstraints {
            $0.centerY.equalTo(nicknameLabel)
            $0.width.equalTo(20)
            $0.right.equalToSuperview().inset(8.0)
            $0.left.equalTo(nicknameLabel.snp.right)
        }
    }
    
    private func bindData() {
        disposeBag = DisposeBag()
        
        reply
            .filter { $0 != nil }
            .map { $0! }
            .bind {
                //            self.profileImageView.image =
                self.nicknameLabel.text = $0.author.nickname
                self.dateLabel.text = $0.date
                self.contentTextView.text = $0.content
                self.likeButton.setTitle("\($0.likes.count)", for: .normal)
            }
            .disposed(by: disposeBag)
        
        self.likeButton.rx.tap.withLatestFrom(reply)
            .filter { $0 != nil }
            .flatMap {
                SubReplyServices.likeSubReply(likeSubReply: PostActivity(boardType: self.boardTpye!, _id: $0!._id, activity: "likes"))
            }
            .do {
                if $0 != nil {
                    self.activityAlert!("좋아요를 했습니다.")
                    self.reply.onNext($0)
                } else {
                    self.activityAlert!("이미 좋아요를 누른 댓글입니다.")
                }
            }
            .delay(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .bind { _ in
                self.dismissAlert!(true)
            }.disposed(by: disposeBag)
        
        self.menubutton.rx.tap.withLatestFrom(reply)
            .filter { $0 != nil }
            .bind {
                self.showMenuAlert(reply: $0!)
            }
            .disposed(by: disposeBag)
    }
    
    private func showMenuAlert(reply: Reply) {
        self.alertDisposeBag = DisposeBag()
        let alert = UIAlertController(title: "메뉴", message: nil, preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: "삭제", style: .default) { _ in
            let delReply = DeletingSubReply(_id: reply._id, boardType: reply.boardType, postId: reply.postId, parentReplyId: reply.parentReplyId!, author: reply.author._id!)
            
            SubReplyServices.deleteSubReply(deletingSubReply: delReply)
                .filter { $0 != nil }
                .do {
                    self.activityAlert!("댓글을 삭제했습니다.")
                    var replies = [Reply]()
                    $0!.forEach {
                        replies.append($0)
                        if $0.childrenReplies != nil &&  $0.childrenReplies!.count > 0 {
                            replies.append(contentsOf: $0.childrenReplies!)
                        }
                    }
                    self.replies.onNext(replies)
                }
                .delay(.seconds(1), scheduler: MainScheduler.asyncInstance)
                .bind { _ in
                    self.dismissAlert!(true)
                }
                .disposed(by: self.alertDisposeBag)
        }
        
        let report = UIAlertAction(title: "신고", style: .default)
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        if Constants.loginUser?._id == reply.author._id {
            alert.addAction(delete)
        }
        alert.addAction(report)
        alert.addAction(cancel)
    
        presentMenuAlert!(alert)
    }
}
