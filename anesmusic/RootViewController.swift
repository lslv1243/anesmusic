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
  // TODO: save api key somewhere else
  let apiClient = ApiClient(apiKey: "93e9a520b0bd3e64a3a0d1be9c2cd5ea")
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    pushViewController(GenresViewController(apiClient: apiClient), animated: false)
  }
}

