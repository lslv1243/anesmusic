//
//  ArtistsViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 09/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit
import SDWebImage

class ArtistsViewController: UITableViewController, UITableViewDataSourcePrefetching, InfinityScrollViewModelDelegate {
  let apiClient: ApiClient
  let genre: GenreItem
  let viewModel: InfinityScrollViewModel<ArtistItem>
  
  init(apiClient: ApiClient, genre: GenreItem) {
    self.apiClient = apiClient
    self.genre = genre
    viewModel = InfinityScrollViewModel { page in
      apiClient.getTopArtists(genre: genre.name, page: page)
    }
    
    super.init(nibName: nil, bundle: nil)
    
    viewModel.delegate = self
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.title = genre.name
    
    refreshControl = UIRefreshControl()
    tableView.refreshControl = refreshControl
    refreshControl!.addTarget(viewModel, action: #selector(viewModel.reload), for: .valueChanged)
    
    tableView.prefetchDataSource = self
    
    viewModel.reload()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let artist = viewModel.items[indexPath.row]
    let albumsViewController = ArtistViewController(apiClient: apiClient, artist: artist)
    navigationController!.pushViewController(albumsViewController, animated: true)
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return "Top Artistas"
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    let artist = viewModel.items[indexPath.row]
    cell.textLabel!.text = artist.name
    cell.imageView!.sd_setImage(
      with: URL(string: artist.imageUrl),
      placeholderImage: UIImage(named: "placeholder")
    )
    return cell
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.items.count
  }
  
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    // if table view wants to prefetch last row, fetch next page
    if (indexPaths.contains { $0.row == viewModel.items.count - 1 }) {
      viewModel.loadMore()
    }
  }
  
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
