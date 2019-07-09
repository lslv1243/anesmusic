//
//  ArtistsViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 09/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit

class ArtistsViewController: UITableViewController, UITableViewDataSourcePrefetching, ArtistsViewModelDelegate {
  let viewModel: ArtistsViewModel
  
  init(apiClient: ApiClient, genre: GenreItem) {
    viewModel = ArtistsViewModel(apiClient: apiClient, genre: genre)
    super.init(nibName: nil, bundle: nil)
    viewModel.delegate = self
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.title = viewModel.genre.name
    
    refreshControl = UIRefreshControl()
    tableView.refreshControl = refreshControl
    refreshControl!.addTarget(viewModel, action: #selector(viewModel.reloadArtists), for: .valueChanged)
    
    tableView.prefetchDataSource = self
    
    viewModel.reloadArtists()
  }
  
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    // if table view wants to prefetch last row, fetch next page
    if (indexPaths.contains { $0.row == viewModel.artists.count - 1 }) {
      viewModel.loadMoreArtists()
    }
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return "Artistas"
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    let artist = viewModel.artists[indexPath.row]
    cell.textLabel!.text = artist.name
    return cell
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.artists.count
  }
  
  func artistsViewModelWillReload() {
    refreshControl!.beginRefreshing()
  }
  
  func artistsViewModelDidReload(error: Error?) {
    if (error == nil) {
      tableView.reloadData()
    }
    refreshControl!.endRefreshing()
  }
  
  func artistsViewModelWillLoadMore() {
    
  }
  
  func artistsViewModelDidLoadMore(error: Error?) {
    if (error == nil) {
      tableView.reloadData()
    }
  }
}

class ArtistsViewModel {
  let apiClient: ApiClient
  let genre: GenreItem
  
  private(set) var currentPage = 0
  private(set) var isFetching = false
  private(set) var hasMore = true
  private(set) var artists: [ArtistItem] = []
  weak var delegate: ArtistsViewModelDelegate?
  
  init(apiClient: ApiClient, genre: GenreItem) {
    self.apiClient = apiClient
    self.genre = genre
  }
  
  @objc func reloadArtists() {
    guard !isFetching else { return }
    
    isFetching = true
    delegate?.artistsViewModelWillReload()
    currentPage = 0
    apiClient.getTopArtists(genre: genre.name, page: 0)
      .done { artists in
        self.artists = artists
        self.delegate?.artistsViewModelDidReload(error: nil)
      }
      .catch { error in
        self.delegate?.artistsViewModelDidReload(error: error)
      }
      .finally {
        self.isFetching = false
      }
  }
  
  func loadMoreArtists() {
    guard !isFetching && hasMore else { return }
    
    isFetching = true
    delegate?.artistsViewModelWillLoadMore()
    currentPage += 1
    apiClient.getTopArtists(genre: genre.name, page: currentPage)
      .done { artists in
        self.hasMore = artists.count != 0
        self.artists.append(contentsOf: artists)
        self.delegate?.artistsViewModelDidLoadMore(error: nil)
      }
      .catch { error in
        self.currentPage -= 1
        self.delegate?.artistsViewModelDidLoadMore(error: error)
      }
      .finally {
        self.isFetching = false
      }
  }
}

protocol ArtistsViewModelDelegate: class {
  func artistsViewModelWillReload()
  func artistsViewModelDidReload(error: Error?)
  func artistsViewModelWillLoadMore()
  func artistsViewModelDidLoadMore(error: Error?)
}
