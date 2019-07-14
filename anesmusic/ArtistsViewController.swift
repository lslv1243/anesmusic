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
    
    view.backgroundColor = AnesColor.background
    tableView.separatorColor = .clear
    
    navigationItem.title = genre.name
    
    refreshControl = UIRefreshControl()
    refreshControl!.tintColor = .white
    tableView.refreshControl = refreshControl
    refreshControl!.addTarget(viewModel, action: #selector(viewModel.reload), for: .valueChanged)
    
    tableView.separatorInset.left = 10
    tableView.separatorInset.right = 10
    
    tableView.prefetchDataSource = self
    
    viewModel.reload()
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let artist = viewModel.items[indexPath.row]
    let albumsViewController = ArtistViewController(apiClient: apiClient, artist: artist)
    navigationController!.pushViewController(albumsViewController, animated: true)
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return SectionHeader(title: "Top Artistas")
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let reuseIdentifier = "ARTIST_CELL"
    let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ArtistTableViewCell
      ?? ArtistTableViewCell(reuseIdentifier: reuseIdentifier)
    let artist = viewModel.items[indexPath.row]
    cell.updateInfo(artist: artist)
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

class ArtistTableViewCell: UITableViewCell {
  let artistImageView = UIImageView(frame: .zero)
  let artistNameLabel = UILabel()
  
  init(reuseIdentifier: String?) {
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
    
    backgroundColor = .clear
    self.selectedBackgroundView = TableViewCellSelectedBackgroundView()
    
    addSubview(artistImageView)
    addSubview(artistNameLabel)
    
    artistImageView.contentMode = .scaleAspectFill
    artistImageView.clipsToBounds = true
    artistImageView.translatesAutoresizingMaskIntoConstraints = false
    artistImageView.layer.cornerRadius = 35
    
    artistNameLabel.font = artistNameLabel.font.withSize(30)
    artistNameLabel.textColor = .white
    artistNameLabel.adjustsFontSizeToFitWidth = true
    artistNameLabel.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      artistImageView.heightAnchor.constraint(equalToConstant: 70),
      artistImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
      artistImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
      artistImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5),
      artistImageView.widthAnchor.constraint(equalTo: artistImageView.heightAnchor)
    ])
    
    NSLayoutConstraint.activate([
      artistNameLabel.centerYAnchor.constraint(equalTo: artistImageView.centerYAnchor),
      artistNameLabel.leadingAnchor.constraint(equalTo: artistImageView.trailingAnchor, constant: 15),
      artistNameLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15)
    ])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func updateInfo(artist: ArtistItem) {
    artistNameLabel.text = artist.name
    artistImageView.sd_setImage(
      with: URL(string: artist.imageUrl.lowQuality ?? ""),
      placeholderImage: UIImage(named: "placeholder")
    )
  }
}
