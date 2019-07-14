//
//  HomeViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 09/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit

class HomeViewController: UITableViewController {
  private let viewModel: HomeViewModel
  let apiClient: ApiClient
  
  init(apiClient: ApiClient) {
    self.apiClient = apiClient
    viewModel = HomeViewModel(apiClient: apiClient)
    
    super.init(nibName: nil, bundle: nil)
    
    viewModel.delegate = self
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
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch (HomeViewControllerSection(rawValue: indexPath.section)!) {
    case .genres:
      let reuseIdentifier = "GENRES_CELL"
      let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? GenresTableViewCell
        ?? GenresTableViewCell(reuseIdentifier: reuseIdentifier)
      cell.updateInfo(genres: viewModel.genres)
      cell.delegate = self
      return cell
    }
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    switch (HomeViewControllerSection(rawValue: section)!) {
    case .genres: return SectionHeader(title: "Gêneros")
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return HomeViewControllerSection.allCases.count
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
}

enum HomeViewControllerSection: Int, CaseIterable {
  case genres = 0
}

extension HomeViewController: HomeViewModelDelegate {
  func homeViewModelWillReload() {
    refreshControl!.beginRefreshing()
  }
  
  func homeViewModelDidReload(error: Error?) {
    if error == nil {
      tableView.reloadData()
    }
    refreshControl!.endRefreshing()
  }
}

extension HomeViewController: GenresTableViewCellDelegate {
  func genresTableViewCell(_ tableViewCell: GenresTableViewCell, didSelectItemAtIndexPath indexPath: IndexPath) {
    let genre = viewModel.genres[indexPath.row]
    let artistsViewController = ArtistsViewController(apiClient: apiClient, genre: genre)
    navigationController!.pushViewController(artistsViewController, animated: true)
  }
}

class HomeViewModel {
  let apiClient: ApiClient
  private(set) var genres: [GenreItem] = []
  // private(set) var artists: [ArtistItem] = []
  private(set) var isFetching = false
  weak var delegate: HomeViewModelDelegate?
  
  init(apiClient: ApiClient) {
    self.apiClient = apiClient
  }
  
  @objc func reload() {
    isFetching = true
    delegate?.homeViewModelWillReload()
    apiClient.getTopGenres()
      .ensure { self.isFetching = false }
      .done { genres in
        self.genres = genres
        self.delegate?.homeViewModelDidReload(error: nil)
      }
      .catch { error in
        self.delegate?.homeViewModelDidReload(error: error)
      }
  }
}

protocol HomeViewModelDelegate: class {
  func homeViewModelWillReload()
  func homeViewModelDidReload(error: Error?)
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
