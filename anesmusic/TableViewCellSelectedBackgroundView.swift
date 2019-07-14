//
//  TableViewCellSelectedBackgroundView.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 13/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit

class TableViewCellSelectedBackgroundView: UIView {
  init() {
    super.init(frame: .zero)
    
    backgroundColor = UIColor.white.withAlphaComponent(0.1)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
