//
//  GenresViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 09/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit

class GenresViewController: UITableViewController {
  let apiClient: ApiClient
  var genres: [Genre] = []
  
  init(apiClient: ApiClient) {
    self.apiClient = apiClient
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.title = "Gêneros"
    
    print("will load genres")
    apiClient.getGenres()
      .done { genres in
        self.genres = genres
        self.tableView.reloadData()
        print("successfully loaded genres")
      }
      .catch { _ in
        print("could not load genres")
      }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    let genre = genres[indexPath.row]
    cell.textLabel!.text = genre.name
    return cell
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return genres.count
  }
}
