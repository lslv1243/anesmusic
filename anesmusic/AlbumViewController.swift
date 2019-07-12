//
//  AlbumViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 12/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit
import SDWebImage

class AlbumViewController: UITableViewController {
  let apiClient: ApiClient
  let album: AlbumItem
  private var albumInfo: AlbumInfo?
  private var isReloading = false
  
  init(apiClient: ApiClient, album: AlbumItem) {
    self.apiClient = apiClient
    self.album = album
    
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.title = album.name
    
    refreshControl = UIRefreshControl()
    tableView.refreshControl = refreshControl
    refreshControl!.addTarget(self, action: #selector(reloadAlbum), for: .valueChanged)
    
    reloadAlbum()
  }
  
  @objc func reloadAlbum() {
    guard !isReloading else { return }
    
    isReloading = true
    refreshControl!.beginRefreshing()
    apiClient.getAlbumInfo(albumId: album.id)
      .done { album in
        self.albumInfo = album
        self.tableView.reloadData()
      }
      .catch { _ in }
      .finally {
        self.isReloading = false
        self.refreshControl!.endRefreshing()
      }
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch (AlbumViewControllerSection(rawValue: section)!) {
    case .cover: return nil
    case .genres: return "Gêneros do Álbum"
    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch (AlbumViewControllerSection(rawValue: indexPath.section)!) {
    case .cover:
      let reuseIdentifier = "ALBUM_CELL"
      let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? AlbumCoverTableViewCell
        ?? AlbumCoverTableViewCell(reuseIdentifier: reuseIdentifier)
      cell.updateInfo(
        coverUrl: albumInfo?.coverUrl ?? album.coverUrl,
        albumName: albumInfo?.name ?? album.name,
        releaseYear: albumInfo?.releaseYear ?? album.releaseYear
      )
      return cell
    case .genres:
      let genre = albumInfo!.genres[indexPath.row]
      let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
      cell.textLabel!.text = genre.name
      return cell
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return AlbumViewControllerSection.allCases.count
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch (AlbumViewControllerSection(rawValue: section)!) {
    case .cover: return 1
    case .genres: return albumInfo?.genres.count ?? 0
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if (AlbumViewControllerSection(rawValue: indexPath.section)! == .genres) {
      let genre = albumInfo!.genres[indexPath.row]
      let genreViewController = ArtistsViewController(apiClient: apiClient, genre: genre)
      navigationController?.pushViewController(genreViewController, animated: true)
    }
  }
}

enum AlbumViewControllerSection: Int, CaseIterable {
  case cover = 0, genres = 1
}

class AlbumCoverTableViewCell: UITableViewCell {
  let coverImageShadow = UIView(frame: .zero)
  let coverImageView = UIImageView(frame: .zero)
  let albumNameLabel = UILabel()
  let releaseYearLabel = UILabel()
  
  init(reuseIdentifier: String) {
    super.init(style: .default, reuseIdentifier: reuseIdentifier)
    
    selectionStyle = .none
    
    addSubview(coverImageShadow)
    coverImageShadow.addSubview(coverImageView)
    addSubview(albumNameLabel)
    addSubview(releaseYearLabel)
    
    coverImageShadow.layer.cornerRadius = 5
    coverImageShadow.layer.shadowColor = UIColor.black.cgColor
    coverImageShadow.layer.shadowOpacity = 0.5
    coverImageShadow.layer.shadowOffset = .zero
    
    coverImageView.layer.cornerRadius = 5
    coverImageView.layer.masksToBounds = true
    coverImageView.contentMode = .scaleToFill
    
    albumNameLabel.font = albumNameLabel.font.withSize(30)
    albumNameLabel.textAlignment = .center
    albumNameLabel.adjustsFontSizeToFitWidth = true
    
    releaseYearLabel.font = releaseYearLabel.font.withSize(15)
    releaseYearLabel.textAlignment = .center
    releaseYearLabel.adjustsFontSizeToFitWidth = true
    releaseYearLabel.textColor = releaseYearLabel.textColor.withAlphaComponent(0.8)
    
    coverImageShadow.translatesAutoresizingMaskIntoConstraints = false
    coverImageView.translatesAutoresizingMaskIntoConstraints = false
    albumNameLabel.translatesAutoresizingMaskIntoConstraints = false
    releaseYearLabel.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      coverImageShadow.heightAnchor.constraint(equalToConstant: 180),
      coverImageShadow.widthAnchor.constraint(equalTo: coverImageShadow.heightAnchor),
      coverImageShadow.centerXAnchor.constraint(equalTo: self.centerXAnchor),
      coverImageShadow.topAnchor.constraint(equalTo: self.topAnchor, constant: 10)
    ])
    
    NSLayoutConstraint.activate([
      coverImageView.leftAnchor.constraint(equalTo: coverImageShadow.leftAnchor),
      coverImageView.topAnchor.constraint(equalTo: coverImageShadow.topAnchor),
      coverImageView.rightAnchor.constraint(equalTo: coverImageShadow.rightAnchor),
      coverImageView.bottomAnchor.constraint(equalTo: coverImageShadow.bottomAnchor)
    ])
    
    NSLayoutConstraint.activate([
      albumNameLabel.centerXAnchor.constraint(equalTo: coverImageView.centerXAnchor),
      albumNameLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 5),
      albumNameLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10),
      albumNameLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10)
    ])
    
    NSLayoutConstraint.activate([
      releaseYearLabel.centerXAnchor.constraint(equalTo: albumNameLabel.centerXAnchor),
      releaseYearLabel.topAnchor.constraint(equalTo: albumNameLabel.bottomAnchor, constant: 5),
      releaseYearLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10),
      releaseYearLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10),
      releaseYearLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10)
    ])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func updateInfo(coverUrl: String, albumName: String, releaseYear: String) {
    coverImageView.sd_setImage(
      with: URL(string: coverUrl),
      placeholderImage: coverImageView.image ?? UIImage(named: "placeholder")
    )
    albumNameLabel.text = albumName
    releaseYearLabel.text = "Lançado em \(releaseYear)"
  }
}
