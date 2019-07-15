//
//  HomeViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 09/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit

class HomeViewController: UITableViewController, ArtistsTableViewCellDelegate, GenresTableViewCellDelegate {
  let viewModel: HomeViewModel
  let apiClient: ApiClient
  let genresDelegateProxy = GenresTableViewCellDelegateProxy()
  let artistsDelegateProxy = ArtistsTableViewCellDelegateProxy()
  var hideSections = false
  
  init(apiClient: ApiClient) {
    self.apiClient = apiClient
    viewModel = HomeViewModel(apiClient: apiClient)
    
    super.init(nibName: nil, bundle: nil)
    
    viewModel.delegate = self
    genresDelegateProxy.proxy = self
    artistsDelegateProxy.proxy = self
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.title = "Início"
    
    view.backgroundColor = AnesColor.background
    tableView.separatorColor = .clear
    
    refreshControl = UIRefreshControl()
    refreshControl!.tintColor = .white
    tableView.refreshControl = refreshControl
    refreshControl!.addTarget(viewModel, action: #selector(viewModel.reload), for: .valueChanged)
    
    viewModel.reload()
    refreshControl!.endRefreshing()
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch (HomeViewControllerSection(rawValue: indexPath.section)!) {
    case .genres:
      let reuseIdentifier = "GENRES_CELL"
      let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? GenresTableViewCell
        ?? GenresTableViewCell(reuseIdentifier: reuseIdentifier)
      cell.updateInfo(genres: viewModel.genres)
      cell.delegate = genresDelegateProxy
      return cell
    case .artists:
      let reuseIdentifier = "ARTISTS_CELL"
      let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? ArtistsTableViewCell
        ?? ArtistsTableViewCell(reuseIdentifier: reuseIdentifier)
      cell.updateInfo(artists: viewModel.artists)
      cell.delegate = artistsDelegateProxy
      cell.dataSource = self
      return cell
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    switch (HomeViewControllerSection(rawValue: section)!) {
    case .genres: return viewModel.genres.count > 0 ? UITableView.automaticDimension : 0
    case .artists: return viewModel.artists.count > 0 ? UITableView.automaticDimension : 0
    }
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    switch (HomeViewControllerSection(rawValue: section)!) {
    case .genres: return viewModel.genres.count > 0 ? SectionHeader(title: "Gêneros") : nil
    case .artists: return viewModel.artists.count > 0 ? SectionHeader(title: "Artistas") : nil
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return HomeViewControllerSection.allCases.count
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch (HomeViewControllerSection(rawValue: section)!) {
    case .genres: return viewModel.genres.count > 0 ? 1 : 0
    case .artists: return viewModel.artists.count > 0 ? 1 : 0
    }
  }
  
  func genresTableViewCell(_ tableViewCell: GenresTableViewCell, didSelectItemAtIndexPath indexPath: IndexPath) {
    let genre = viewModel.genres[indexPath.row]
    let artistsViewController = ArtistsViewController(apiClient: apiClient, genre: genre)
    navigationController!.pushViewController(artistsViewController, animated: true)
  }

  func artistsTableViewCell(_ tableViewCell: ArtistsTableViewCell, didSelectItemAtIndexPath indexPath: IndexPath) {
    let artist = viewModel.artists[indexPath.row]
    let artistViewController = ArtistViewController(apiClient: apiClient, artist: artist)
    navigationController!.pushViewController(artistViewController, animated: true)
  }
}

enum HomeViewControllerSection: Int, CaseIterable {
  case genres = 0, artists = 1
}

extension HomeViewController: HomeViewModelDelegate {
  func homeViewModelWillReload() {
    refreshControl?.beginRefreshing()
  }
  
  func homeViewModelDidReload(error: Error?) {
    if error == nil {
      tableView.reloadData()
    }
    refreshControl?.endRefreshing()
  }
  
  func homeViewModelWillLoadMoreArtists() {
  }
  
  func homeViewModelDidLoadMoreArtists(error: Error?) {
    tableView.reloadData()
  }
}

extension HomeViewController: ArtistsTableViewCellDataSource {
  func shouldLoadMoreForArtistsTableViewCell(_ tableViewCell: ArtistsTableViewCell) {
    viewModel.loadMoreArtists()
  }
}

class HomeViewModel {
  private let infinityArtists: InfinityScrollViewModel<ArtistItem>
  let apiClient: ApiClient
  private(set) var genres: [GenreItem] = []
  var artists: [ArtistItem] {
    get { return infinityArtists.items }
  }
  private var isFetchingGenres = false
  var isFetching: Bool {
    return isFetchingGenres || infinityArtists.isFetching
  }
  weak var delegate: HomeViewModelDelegate?
  
  init(apiClient: ApiClient) {
    infinityArtists = InfinityScrollViewModel { page, search in
      apiClient.getTopArtists(page: page, search: search)
    }
    
    self.apiClient = apiClient
    
    infinityArtists.delegate = self
  }
  
  @objc func reload(search: String = "") {
    guard !isFetching else { return }
    
    isFetchingGenres = true
    delegate?.homeViewModelWillReload()
    infinityArtists.reload(search: search)
    apiClient.getTopGenres()
      .ensure { self.isFetchingGenres = false }
      .done { genres in
        var filteredGenres = genres
        if !search.isEmpty {
          filteredGenres = filteredGenres.filter { $0.name.contains(search) }
        }
        self.genres = filteredGenres
        if !self.infinityArtists.isFetching {
          self.delegate?.homeViewModelDidReload(error: nil)
        }
      }
      .catch { error in
        if !self.infinityArtists.isFetching {
          // FIXME: getting only last error
          self.delegate?.homeViewModelDidReload(error: error)
        }
      }
  }
  
  func loadMoreArtists() {
    infinityArtists.loadMore()
  }
}

extension HomeViewModel: InfinityScrollViewModelDelegate {
  func infinityScrollViewModelWillReload() {
  }
  
  func infinityScrollViewModelDidReload(error: Error?) {
    if !isFetchingGenres {
      // FIXME: getting only last error
      delegate?.homeViewModelDidReload(error: error)
    }
  }
  
  func infinityScrollViewModelWillLoadMore() {
    delegate?.homeViewModelWillLoadMoreArtists()
  }
  
  func infinityScrollViewModelDidLoadMore(error: Error?) {
    delegate?.homeViewModelDidLoadMoreArtists(error: error)
  }
}

protocol HomeViewModelDelegate: class {
  func homeViewModelWillReload()
  func homeViewModelDidReload(error: Error?)
  func homeViewModelWillLoadMoreArtists()
  func homeViewModelDidLoadMoreArtists(error: Error?)
}

class GenresTableViewCell: UITableViewCell {
  private let genreReuseIdenfier = "GENRE_ITEM"
  private let collectionView: UICollectionView
  private(set) var genres: [GenreItem] = []
  weak var delegate: GenresTableViewCellDelegate?
  
  init(reuseIdentifier: String?) {
    let collectionViewLayout = UICollectionViewFlowLayout()
    collectionViewLayout.scrollDirection = .horizontal
    collectionViewLayout.itemSize = CGSize(width: 150, height: 150)
    collectionViewLayout.minimumLineSpacing = 15
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
    
    backgroundColor = .clear
    
    addSubview(collectionView)
    
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.contentInset.left = 15
    collectionView.contentInset.right = 15
    collectionView.backgroundColor = .clear
    collectionView.delegate = self
    collectionView.dataSource = self
    
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      collectionView.heightAnchor.constraint(equalToConstant: 150),
      collectionView.topAnchor.constraint(equalTo: self.topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      collectionView.leftAnchor.constraint(equalTo: self.leftAnchor),
      collectionView.rightAnchor.constraint(equalTo: self.rightAnchor)
    ])
    
    collectionView.register(GenreCollectionViewCell.self, forCellWithReuseIdentifier: genreReuseIdenfier)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func updateInfo(genres: [GenreItem]) {
    self.genres = genres
    collectionView.reloadData()
  }
}

protocol GenresTableViewCellDelegate: class {
  func genresTableViewCell(_ tableViewCell: GenresTableViewCell, didSelectItemAtIndexPath indexPath: IndexPath)
}

class GenresTableViewCellDelegateProxy: GenresTableViewCellDelegate {
  var proxy: GenresTableViewCellDelegate?
  
  func genresTableViewCell(_ tableViewCell: GenresTableViewCell, didSelectItemAtIndexPath indexPath: IndexPath) {
    proxy?.genresTableViewCell(tableViewCell, didSelectItemAtIndexPath: indexPath)
  }
}

extension GenresTableViewCell: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return genres.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let genre = genres[indexPath.row]
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: genreReuseIdenfier, for: indexPath) as! GenreCollectionViewCell
    cell.updateInfo(genreName: genre.name)
    return cell
  }
}

extension GenresTableViewCell: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    delegate?.genresTableViewCell(self, didSelectItemAtIndexPath: indexPath)
  }
}

class GenreCollectionViewCell: UICollectionViewCell {
  private let genreNameLabel = UILabel()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = AnesColor.lightBackground
    
    addSubview(genreNameLabel)
    
    genreNameLabel.textColor = .white
    genreNameLabel.font = genreNameLabel.font.withSize(30)
    genreNameLabel.font = UIFont(
      descriptor: genreNameLabel.font.fontDescriptor.withSymbolicTraits([.traitBold])!,
      size: 0
    )
    genreNameLabel.textAlignment = .center
    genreNameLabel.adjustsFontSizeToFitWidth = true
    
    genreNameLabel.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      genreNameLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15),
      genreNameLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -15),
      genreNameLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
    ])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func updateInfo(genreName: String) {
    genreNameLabel.text = genreName
  }
}

class ArtistsTableViewCell: UITableViewCell {
  private let artistReuseIdentifier = "ARTIST_ITEM"
  private let collectionView: UICollectionView
  private(set) var artists: [ArtistItem] = []
  weak var delegate: ArtistsTableViewCellDelegate?
  weak var dataSource: ArtistsTableViewCellDataSource?
  
  init(reuseIdentifier: String?) {
    let guessedMaximumCellHeight: CGFloat = 188
    
    let collectionViewLayout = UICollectionViewFlowLayout()
    collectionViewLayout.scrollDirection = .horizontal
    collectionViewLayout.itemSize = CGSize(width: 150, height: guessedMaximumCellHeight)
    collectionViewLayout.minimumLineSpacing = 15
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
    
    backgroundColor = .clear
    
    addSubview(collectionView)
    
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.contentInset.left = 15
    collectionView.contentInset.right = 15
    collectionView.backgroundColor = .clear
    collectionView.delegate = self
    collectionView.dataSource = self
    
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      collectionView.heightAnchor.constraint(equalToConstant: guessedMaximumCellHeight),
      collectionView.topAnchor.constraint(equalTo: self.topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      collectionView.leftAnchor.constraint(equalTo: self.leftAnchor),
      collectionView.rightAnchor.constraint(equalTo: self.rightAnchor)
    ])
    
    collectionView.register(ArtistCollectionViewCell.self, forCellWithReuseIdentifier: artistReuseIdentifier)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func updateInfo(artists: [ArtistItem]) {
    self.artists = artists
    collectionView.reloadData()
  }
}

protocol ArtistsTableViewCellDelegate: class {
  func artistsTableViewCell(_ tableViewCell: ArtistsTableViewCell, didSelectItemAtIndexPath indexPath: IndexPath)
}

protocol ArtistsTableViewCellDataSource: class {
  func shouldLoadMoreForArtistsTableViewCell(_ tableViewCell: ArtistsTableViewCell)
}

class ArtistsTableViewCellDelegateProxy: ArtistsTableViewCellDelegate {
  var proxy: ArtistsTableViewCellDelegate?
  
  func artistsTableViewCell(_ tableViewCell: ArtistsTableViewCell, didSelectItemAtIndexPath indexPath: IndexPath) {
    proxy?.artistsTableViewCell(tableViewCell, didSelectItemAtIndexPath: indexPath)
  }
}

extension ArtistsTableViewCell: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return artists.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let artist = artists[indexPath.row]
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: artistReuseIdentifier, for: indexPath) as! ArtistCollectionViewCell
    cell.updateInfo(artistName: artist.name, artistImageUrl: artist.imageUrl.mediumQuality ?? "")
    return cell
  }
}

extension ArtistsTableViewCell: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    delegate?.artistsTableViewCell(self, didSelectItemAtIndexPath: indexPath)
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if indexPath.row == artists.count - 1 {
      dataSource?.shouldLoadMoreForArtistsTableViewCell(self)
    }
  }
}

class ArtistCollectionViewCell: UICollectionViewCell {
  private let artistImageView = UIImageView(frame: .zero)
  private let artistNameLabel = UILabel()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    addSubview(artistImageView)
    addSubview(artistNameLabel)
    
    artistImageView.layer.cornerRadius = 75
    artistImageView.clipsToBounds = true
    artistImageView.contentMode = .scaleAspectFill
    
    artistNameLabel.textColor = .white
    artistNameLabel.font = artistNameLabel.font.withSize(30)
    artistNameLabel.font = UIFont(
      descriptor: artistNameLabel.font.fontDescriptor.withSymbolicTraits([.traitBold])!,
      size: 0
    )
    artistNameLabel.textAlignment = .center
    artistNameLabel.adjustsFontSizeToFitWidth = true
    
    artistImageView.translatesAutoresizingMaskIntoConstraints = false
    artistNameLabel.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      artistImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
      artistImageView.topAnchor.constraint(equalTo: self.topAnchor),
      artistImageView.widthAnchor.constraint(equalTo: self.widthAnchor),
      artistImageView.heightAnchor.constraint(equalTo: artistImageView.widthAnchor)
    ])
    
    NSLayoutConstraint.activate([
      artistNameLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15),
      artistNameLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -15),
      artistNameLabel.topAnchor.constraint(equalTo: artistImageView.bottomAnchor, constant: 5)
      // cannot stick to the bottom, gotta guess the height of the cell
    ])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func updateInfo(artistName: String, artistImageUrl: String) {
    artistNameLabel.text = artistName
    artistImageView.sd_setImage(
      with: URL(string: artistImageUrl),
      placeholderImage: UIImage(named: "placeholder")
    )
  }
}
