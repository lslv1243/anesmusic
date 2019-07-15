//
//  SearchableHomeViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 14/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit

class SearchableHomeViewController: HomeViewController {
  private var searchController: UISearchController!
  private var resultsViewController: HomeViewController!
  
  override init(apiClient: ApiClient) {
    super.init(apiClient: apiClient)
    
    resultsViewController = HomeViewController(apiClient: apiClient)
    resultsViewController.tableView.delegate = self
    resultsViewController.genresDelegateProxy.proxy = self
    resultsViewController.artistsDelegateProxy.proxy = self
    resultsViewController.refreshControl = nil
    
    searchController = UISearchController(searchResultsController: resultsViewController)
    searchController.searchBar.barTintColor = .clear
    
    // hack to change the button color, but not the cursor
    let defaultTintColor = searchController.searchBar.tintColor
    searchController.searchBar.tintColor = .white
    searchController.searchBar.subviews[0].subviews.compactMap(){ $0 as? UITextField }.first?.tintColor = defaultTintColor
    
    tableView.tableHeaderView = searchController.searchBar
    tableView.backgroundView = UIView(frame: .zero)
    
    searchController.searchResultsUpdater = self
    definesPresentationContext = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func genresTableViewCell(_ tableViewCell: GenresTableViewCell, didSelectItemAtIndexPath indexPath: IndexPath) {
    let genre = resultsViewController.viewModel.genres[indexPath.row]
    let artistsViewController = ArtistsViewController(apiClient: apiClient, genre: genre)
    navigationController!.pushViewController(artistsViewController, animated: true)
  }
  
  override func artistsTableViewCell(_ tableViewCell: ArtistsTableViewCell, didSelectItemAtIndexPath indexPath: IndexPath) {
    let artist = resultsViewController.viewModel.artists[indexPath.row]
    let artistViewController = ArtistViewController(apiClient: apiClient, artist: artist)
    navigationController!.pushViewController(artistViewController, animated: true)
  }
}

extension SearchableHomeViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    let search = searchController.searchBar.text!.trimmingCharacters(in: .whitespaces)
    resultsViewController.viewModel.reload(search: search)
  }
}
