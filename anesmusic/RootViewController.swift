//
//  ViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 08/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit
import Alamofire

class RootViewController: UINavigationController {
  let apiClient = ApiClient()
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    pushViewController(GenresViewController(apiClient: apiClient), animated: false)
  }
}

