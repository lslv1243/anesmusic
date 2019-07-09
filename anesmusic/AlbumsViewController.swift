//
//  AlbumsViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 09/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit
import SDWebImage

class AlbumsViewController: UITableViewController, UITableViewDataSourcePrefetching, InfinityScrollViewModelDelegate {
  let apiClient: ApiClient
  let artist: ArtistItem
  let viewModel: InfinityScrollViewModel<AlbumItem>
  
  init(apiClient: ApiClient, artist: ArtistItem) {
    self.apiClient = apiClient
    self.artist = artist
    viewModel = InfinityScrollViewModel { page in
      apiClient.getTopAlbums(artistId: artist.id, page: page)
    }
    
    super.init(nibName: nil, bundle: nil)
    
    viewModel.delegate = self
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.title = artist.name
    
    refreshControl = UIRefreshControl()
    tableView.refreshControl = refreshControl
    refreshControl!.addTarget(viewModel, action: #selector(viewModel.reload), for: .valueChanged)
    
    tableView.prefetchDataSource = self
    
    viewModel.reload()
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return "Álbuns"
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cellIdentifier = "ALBUM_CELL"
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
      ?? UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
    let album = viewModel.items[indexPath.row]
    cell.textLabel!.text = album.name
    cell.imageView!.sd_setImage(
      with: URL(string: album.coverUrl),
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
