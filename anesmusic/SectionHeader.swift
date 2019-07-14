//
//  SectionHeader.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 13/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit

class SectionHeader: UIView {
  private let titleLabel = UILabel()
  
  convenience init(title: String) {
    self.init(frame: .zero)
    
    titleLabel.text = title
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = AnesColor.background.withAlphaComponent(0.95)
    
    addSubview(titleLabel)
    
    titleLabel.textColor = .white
    titleLabel.font = titleLabel.font.withSize(20)
    titleLabel.textAlignment = .center
    
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10),
      titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10),
      titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
      titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10)
      ])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
