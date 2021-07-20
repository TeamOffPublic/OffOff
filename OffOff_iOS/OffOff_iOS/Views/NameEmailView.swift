//
//  NameEmailView.swift
//  OffOff_iOS
//
//  Created by Lee Nam Jun on 2021/07/20.
//

import UIKit
import SnapKit

class NameEmailView: UIView {
    var nameTextField = TextField().then {
        $0.placeholder = "이름"
        $0.font = UIFont.preferredFont(forTextStyle: .callout)
        $0.adjustsFontForContentSizeCategory = true
        $0.tintColor = .mainColor
        $0.backgroundColor = .white
        $0.autocapitalizationType = .none
        $0.clearButtonMode = .whileEditing
        $0.autocorrectionType = .no
        
        $0.setupTextField(selectedColor: .mainColor, normalColor: .gray, iconImage: .ICON_USER_GRAY, errorColor: .red)
    }
    
    var emailTextField = TextField().then {
        $0.placeholder = "이메일 (ex: abcd@abcd.com)"
        $0.font = UIFont.preferredFont(forTextStyle: .callout)
        $0.adjustsFontForContentSizeCategory = true
        $0.tintColor = .mainColor
        $0.backgroundColor = .white
        $0.autocapitalizationType = .none
        $0.clearButtonMode = .whileEditing
        $0.autocorrectionType = .no
        $0.textContentType = .emailAddress
        
        $0.setupTextField(selectedColor: .mainColor, normalColor: .gray, iconImage: .ICON_AT_GRAY, errorColor: .red)
    }
    
    var nextButton = UIButton().then {
        $0.backgroundColor = .mainColor
        $0.setTitle("다음", for: .normal)
        $0.setTitleColor(.white, for: .normal)
    }
    
    var textFieldStack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 18
        $0.distribution = .fill
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        self.addSubview(textFieldStack)
        self.addSubview(nextButton)
        textFieldStack.addArrangedSubview(nameTextField)
        textFieldStack.addArrangedSubview(emailTextField)
        makeView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeView() {
        nextButton.snp.makeConstraints {
            $0.bottom.equalTo(self.snp.centerY)
            $0.width.equalToSuperview().dividedBy(1.25)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(UIScreen.main.bounds.size.height / 10.0)
        }
        
        textFieldStack.snp.makeConstraints {
            $0.width.equalToSuperview().dividedBy(1.25)
            $0.bottom.equalTo(nextButton.snp.top).offset(-30)
            $0.centerX.equalToSuperview()
        }
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI
@available(iOS 13.0, *)
struct PREVIEW: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            let view = NameEmailView()
            return view
        }.previewLayout(.sizeThatFits)
    }
}

#endif

