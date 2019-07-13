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
  let apiClient = ApiClient(
    clientId: "85fc99fb6f544351bcddd595d70b6e0a",
    clientSecret: "a4f58e5e442f4880b02ad6f24f82e0be"
  )
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    navigationBar.barStyle = .black
    navigationBar.tintColor = .white
    
    pushViewController(GenresViewController(apiClient: apiClient), animated: false)
  }
}

