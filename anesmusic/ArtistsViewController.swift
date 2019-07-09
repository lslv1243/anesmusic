//
//  ArtistsViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 09/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit

class ArtistsViewController: UITableViewController {
  let apiClient: ApiClient
  let genre: GenreItem
  var artists: [ArtistItem] = []
  
  init(apiClient: ApiClient, genre: GenreItem) {
    self.apiClient = apiClient
    self.genre = genre
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.title = "Artistas"
    
    refreshControl = UIRefreshControl()
    tableView.refreshControl = refreshControl
    refreshControl!.addTarget(self, action: #selector(loadArtists), for: .valueChanged)
    
    loadArtists()
  }
  
  @objc private func loadArtists() {
    refreshControl!.beginRefreshing()
    print("will load artists")
    apiClient.getTopArtists(genre: genre.name, page: 0)
      .done { artists in
        self.artists = artists
        self.tableView.reloadData()
        print("successfully loaded artists")
      }
      .catch { _ in
        print("could not load artists")
      }
      .finally {
          self.refreshControl!.endRefreshing()
      }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    let artist = artists[indexPath.row]
    cell.textLabel!.text = artist.name
    return cell
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return artists.count
  }

}
