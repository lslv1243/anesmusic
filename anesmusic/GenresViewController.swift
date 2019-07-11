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
  var isFetching = false
  var genres: [GenreItem] = []
  
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
    
    refreshControl = UIRefreshControl()
    tableView.refreshControl = refreshControl
    refreshControl!.addTarget(self, action: #selector(reloadGenres), for: .valueChanged)
    
    reloadGenres()
  }
  
  @objc func reloadGenres() {
    guard !isFetching else { return }
    
    isFetching = true
    refreshControl!.beginRefreshing()
    
    apiClient.getTopGenres()
      .done { genres in
        self.genres = genres
        self.tableView.reloadData()
      }
      .catch { _ in }
      .finally {
        self.isFetching = false
        self.refreshControl!.endRefreshing()
      }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let genre = genres[indexPath.row]
    let artistsViewController = ArtistsViewController(apiClient: apiClient, genre: genre)
    navigationController!.pushViewController(artistsViewController, animated: true)
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

extension GenresViewController: InfinityScrollViewModelDelegate {
  func infinityScrollViewModelWillReload() {
    refreshControl!.beginRefreshing()
  }
  
  func infinityScrollViewModelDidReload(error: Error?) {
    if (error == nil) {
      tableView.reloadData()
    }
    refreshControl!.endRefreshing()
  }
  
  func infinityScrollViewModelWillLoadMore() {
    
  }
  
  func infinityScrollViewModelDidLoadMore(error: Error?) {
    if (error == nil) {
      tableView.reloadData()
    }
  }
}
