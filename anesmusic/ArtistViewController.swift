//
//  ArtistViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 09/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit
import SDWebImage

class ArtistViewController: UITableViewController {
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
    switch (ArtistViewControllerSection(rawValue: section)!) {
    case .info: return nil
    case .albums: return "Top Álbuns"
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch (ArtistViewControllerSection(rawValue: indexPath.section)!) {
    case .info:
      let cellIdentifier = "INFO_CELL"
      let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? ArtistInfoTableViewCell
        ?? ArtistInfoTableViewCell(reuseIdentifier: cellIdentifier)
      cell.updateInfo(artist: artist)
      return cell
    case .albums:
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
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return ArtistViewControllerSection.allCases.count
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch (ArtistViewControllerSection(rawValue: section)!) {
    case .info: return 1
    case .albums: return viewModel.items.count
    }
  }
}

extension ArtistViewController: UITableViewDataSourcePrefetching {
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    // if table view wants to prefetch last row, fetch next page
    if (indexPaths.contains { $0.row == viewModel.items.count - 1 }) {
      viewModel.loadMore()
    }
  }
}

extension ArtistViewController: InfinityScrollViewModelDelegate {
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

enum ArtistViewControllerSection: Int, CaseIterable {
  case info = 0, albums = 1
}

class ArtistInfoTableViewCell: UITableViewCell {
  private let artistImageView = UIImageView(frame: .zero)
  private let artistNameLabel = UILabel()
  
  init(reuseIdentifier: String?) {
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
    
    addSubview(artistImageView)
    addSubview(artistNameLabel)
    
    artistImageView.contentMode = .scaleAspectFill
    artistImageView.clipsToBounds = true
    artistNameLabel.font = artistNameLabel.font.withSize(50)
    artistNameLabel.adjustsFontSizeToFitWidth = true
    artistNameLabel.textAlignment = .center
    
    artistImageView.translatesAutoresizingMaskIntoConstraints = false
    artistNameLabel.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      self.heightAnchor.constraint(equalToConstant: 200),
    ])
    
    NSLayoutConstraint.activate([
      artistImageView.topAnchor.constraint(equalTo: self.topAnchor),
      artistImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
      artistImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
      artistImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
    ])
    
    NSLayoutConstraint.activate([
      artistNameLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
      artistNameLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20),
      artistNameLabel.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -40)
    ])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func updateInfo(artist: ArtistItem) {
    artistImageView.sd_setImage(
      with: URL(string: artist.imageUrl),
      placeholderImage: UIImage(named: "placeholder")
    )
    artistNameLabel.text = artist.name
  }
}
