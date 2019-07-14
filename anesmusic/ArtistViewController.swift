//
//  ArtistViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 09/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit
import SDWebImage
import PromiseKit

class ArtistViewController: HiddenNavbarTableViewController {
  let apiClient: ApiClient
  let artist: ArtistItem
  let viewModel: ArtistViewModel
  
  override var headerHeight: CGFloat {
    get { return view.bounds.width }
    set {}
  }
  
  init(apiClient: ApiClient, artist: ArtistItem) {
    self.apiClient = apiClient
    self.artist = artist
    viewModel = ArtistViewModel(apiClient: apiClient, artistItem: artist)
    
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
    
    navigationItem.title = artist.name
    
    refreshControl = UIRefreshControl()
    refreshControl!.tintColor = .white
    tableView.refreshControl = refreshControl
    refreshControl!.addTarget(viewModel, action: #selector(viewModel.reload), for: .valueChanged)
    
    tableView.prefetchDataSource = self
    
    viewModel.reload()
    
    refreshControl!.endRefreshing()
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if ArtistViewControllerSection(rawValue: section)! == .info {
      return 0
    }
    return UITableView.automaticDimension
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    switch (ArtistViewControllerSection(rawValue: section)!) {
    case .info: return nil
    case .genres: return SectionHeader(title: "Gêneros do artista")
    case .albums: return SectionHeader(title: "Top Álbuns")
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch (ArtistViewControllerSection(rawValue: indexPath.section)!) {
    case .info:
      let cellIdentifier = "INFO_CELL"
      let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? ArtistInfoTableViewCell
        ?? ArtistInfoTableViewCell(reuseIdentifier: cellIdentifier)
      cell.updateInfo(
        imageUrl: viewModel.artist?.imageUrl.highQuality ?? artist.imageUrl.highQuality ?? "",
        artistName: viewModel.artist?.name ?? artist.name
      )
      return cell
    case .genres:
      let cellIdentifier = "GENRE_CELL"
      let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        ?? UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
      let genre = viewModel.artist!.genres[indexPath.row]
      cell.textLabel!.text = genre.name
      cell.textLabel!.textColor = .white
      cell.backgroundColor = .clear
      cell.selectedBackgroundView = TableViewCellSelectedBackgroundView()
      return cell
    case .albums:
      let cellIdentifier = "ALBUM_CELL"
      let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        ?? UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
      let album = viewModel.albums[indexPath.row]
      cell.textLabel!.text = album.name
      cell.imageView!.clipsToBounds = true
      cell.imageView!.contentMode = .scaleAspectFill
      cell.imageView!.sd_setImage(
        with: album.coverUrl.lowQuality.flatMap { URL(string: $0) },
        placeholderImage: UIImage(named: "placeholder")
      )
      cell.textLabel!.textColor = .white
      cell.backgroundColor = .clear
      cell.selectedBackgroundView = TableViewCellSelectedBackgroundView()
      return cell
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return ArtistViewControllerSection.allCases.count
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch (ArtistViewControllerSection(rawValue: section)!) {
    case .info: return 1
    case .genres: return viewModel.artist?.genres.count ?? 0
    case .albums: return viewModel.albums.count
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch (ArtistViewControllerSection(rawValue: indexPath.section)!) {
    case .info: break
    case .genres:
      let genre = viewModel.artist!.genres[indexPath.row]
      let genreViewController = ArtistsViewController(apiClient: apiClient, genre: genre)
      navigationController!.pushViewController(genreViewController, animated: true)
    case .albums:
      let album = viewModel.albums[indexPath.row]
      let albumViewController = AlbumViewController(apiClient: apiClient, album: album)
      navigationController!.pushViewController(albumViewController, animated: true)
    }
  }
}

extension ArtistViewController: UITableViewDataSourcePrefetching {
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    // if table view wants to prefetch albums' last row, fetch next page
    let albumsIndexPaths = indexPaths.filter { ArtistViewControllerSection(rawValue: $0.section)! == .albums }
    if (albumsIndexPaths.contains { $0.row == viewModel.albums.count - 1 }) {
      viewModel.loadMoreAlbums()
    }
  }
}

extension ArtistViewController: ArtistViewModelDelegate {
  func artistViewModelWillReload() {
    refreshControl!.beginRefreshing()
  }
  
  func artistViewModelDidReload(error: Error?) {
    if (error == nil) {
      tableView.reloadData()
    }
    refreshControl!.endRefreshing()
  }
  
  func artistViewModelWillLoadMoreAlbums() {
    
  }
  
  func artistViewModelDidLoadMoreAlbums(error: Error?) {
    if (error == nil) {
      tableView.reloadData()
    }
  }
}

enum ArtistViewControllerSection: Int, CaseIterable {
  case info = 0, genres = 1, albums = 2
}

class ArtistInfoTableViewCell: UITableViewCell {
  private let artistImageGradient = CAGradientLayer()
  private let artistImageView = UIImageView(frame: .zero)
  private let artistNameLabel = UILabel()
  
  init(reuseIdentifier: String?) {
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
    
    addSubview(artistImageView)
    addSubview(artistNameLabel)
    
    artistImageGradient.colors = [
      AnesColor.background.cgColor,
      UIColor.black.withAlphaComponent(0.2).cgColor,
      UIColor.black.withAlphaComponent(0.1).cgColor,
      UIColor.black.withAlphaComponent(0.5).cgColor,
      AnesColor.background.cgColor
    ]
    artistImageView.layer.insertSublayer(artistImageGradient, at: 0)
    
    artistImageView.contentMode = .scaleAspectFill
    artistImageView.clipsToBounds = true
    artistNameLabel.font = artistNameLabel.font.withSize(50)
    artistNameLabel.font = UIFont(
      descriptor: artistNameLabel.font.fontDescriptor.withSymbolicTraits([.traitBold])!,
      size: 0
    )
    artistNameLabel.adjustsFontSizeToFitWidth = true
    artistNameLabel.textAlignment = .center
    artistNameLabel.textColor = .white
    
    artistImageView.translatesAutoresizingMaskIntoConstraints = false
    artistNameLabel.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      artistImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
      artistImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
      artistImageView.heightAnchor.constraint(equalTo: artistImageView.widthAnchor),
      artistImageView.topAnchor.constraint(equalTo: self.topAnchor),
      artistImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
    ])
    
    NSLayoutConstraint.activate([
      artistNameLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
      artistNameLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -40),
      artistNameLabel.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -40)
    ])
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    artistImageGradient.frame = self.bounds
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func updateInfo(imageUrl: String, artistName: String) {
    artistImageView.sd_setImage(
      with: URL(string: imageUrl),
      // maybe the lower resolution image has already being loaded
      placeholderImage: artistImageView.image ?? UIImage(named: "placeholder")
    )
    artistNameLabel.text = artistName
  }
}

class ArtistViewModel {
  private let infinityScroll: InfinityScrollViewModel<AlbumItem>
  private(set) var artist: ArtistInfo?
  var albums: [AlbumItem] {
    get { return infinityScroll.items }
  }
  let apiClient: ApiClient
  let artistItem: ArtistItem
  
  private var isFetchingAlbums: Bool {
    get { return infinityScroll.isFetching }
  }
  private var isFetchingInfo = false
  var isFetching: Bool {
    get { return isFetchingAlbums || isFetchingInfo }
  }
  
  weak var delegate: ArtistViewModelDelegate?

  init(apiClient: ApiClient, artistItem: ArtistItem) {
    self.apiClient = apiClient
    self.artistItem = artistItem
    infinityScroll = InfinityScrollViewModel { page in
      apiClient.getTopAlbums(artistId: artistItem.id, page: page)
    }
    infinityScroll.delegate = self
  }
  
  @objc func reload() {
    guard !isFetching else { return }
    
    isFetchingInfo = true
    delegate?.artistViewModelWillReload()
    infinityScroll.reload()
    apiClient.getArtistInfo(artistId: artistItem.id)
      .ensure {
        self.isFetchingInfo = false
      }
      .done { artist in
        self.artist = artist
        if (!self.isFetchingAlbums) {
          self.delegate?.artistViewModelDidReload(error: nil)
        }
      }
      .catch { error in
        if (!self.isFetchingAlbums) {
          // FIXME: getting only last error
          self.delegate?.artistViewModelDidReload(error: error)
        }
      }
  }
  
  func loadMoreAlbums() {
    guard !isFetching else { return }
    
    infinityScroll.loadMore()
  }
}

extension ArtistViewModel: InfinityScrollViewModelDelegate {
  func infinityScrollViewModelWillReload() {
  }
  
  func infinityScrollViewModelDidReload(error: Error?) {
    if (!isFetchingInfo) {
      // FIXME: getting only last error
      delegate?.artistViewModelDidReload(error: error)
    }
  }
  
  func infinityScrollViewModelWillLoadMore() {
    delegate?.artistViewModelWillLoadMoreAlbums()
  }
  
  func infinityScrollViewModelDidLoadMore(error: Error?) {
    delegate?.artistViewModelDidLoadMoreAlbums(error: error)
  }
}

protocol ArtistViewModelDelegate: class {
  func artistViewModelWillReload()
  func artistViewModelDidReload(error: Error?)
  func artistViewModelWillLoadMoreAlbums()
  func artistViewModelDidLoadMoreAlbums(error: Error?)
}
