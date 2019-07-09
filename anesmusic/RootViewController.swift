//
//  ViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 08/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit
import Alamofire

class RootViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let apiClient = ApiClient()
    apiClient.getGenres(page: 0)
      .done { genres in
        for genre in genres {
          print(genre)
        }
      }
      .catch { _ in
        print("Não foi possível carregar os gêneros!")
      }
  }
}

