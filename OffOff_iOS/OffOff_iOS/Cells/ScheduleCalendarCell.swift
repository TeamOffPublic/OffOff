//
//  ScheduleCalendarCell.swift
//  OffOff_iOS
//
//  Created by Lee Nam Jun on 2021/08/23.
//

import RxSwift

class ScheduleCalendarCell: FSCalendarCell {
    static let identifier = "ScheduleCalendarCell"
    
    var savedShift = BehaviorSubject<SavedShift?>(value: nil)
    let disposeBag = DisposeBag()
    
    var eventTitleLabel = UILabel().then {
        $0.textAlignment = .center
    }
    
    override init!(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(eventTitleLabel)
        eventTitleLabel.snp.makeConstraints {
            $0.top.equalTo(self.titleLabel.snp.bottom).offset(2.5)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(self.contentView.snp.height).dividedBy(2.0)
        }
        self.titleLabel.snp.removeConstraints()
        self.titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.left.right.equalToSuperview()
        }
        
        savedShift
            .observeOn(MainScheduler.instance)
            .bind {
                if $0 != nil {
                    self.eventTitleLabel.text = "\($0!.shift!.title.first!)"
                    self.eventTitleLabel.textColor = UIColor(hex: $0!.shift!.textColor)
                    self.eventTitleLabel.backgroundColor = UIColor(hex: $0!.shift!.backgroundColor)
                } else {
                    self.eventTitleLabel.text = nil
                    self.eventTitleLabel.backgroundColor = .white
                    self.eventTitleLabel.textColor = .black
                }
                
            }
            .disposed(by: disposeBag)
    }
    
    required init!(coder aDecoder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
}
