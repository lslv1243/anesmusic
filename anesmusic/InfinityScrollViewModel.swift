//
//  InfinityScrollViewModel.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 09/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import PromiseKit

class InfinityScrollViewModel<T> {
  private(set) var currentPage = 0
  private(set) var isFetching = false
  private(set) var hasMore = true
  private(set) var items: [T] = []
  weak var delegate: InfinityScrollViewModelDelegate?
  
  private let fetchPage: (_ page: Int) -> Promise<[T]>
  
  init(fetchPage: @escaping (_ page: Int) -> Promise<[T]>) {
    self.fetchPage = fetchPage
  }
  
  @objc func reload() {
    guard !isFetching else { return }
    
    isFetching = true
    delegate?.infinityScrollViewModelWillReload()
    currentPage = 0
    fetchPage(0)
      .done { items in
        self.items = items
        self.delegate?.infinityScrollViewModelDidReload(error: nil)
      }
      .catch { error in
        self.delegate?.infinityScrollViewModelDidReload(error: error)
      }
      .finally {
        self.isFetching = false
    }
  }
  
  func loadMore() {
    guard !isFetching && hasMore else { return }
    
    isFetching = true
    delegate?.infinityScrollViewModelWillLoadMore()
    currentPage += 1
    fetchPage(currentPage)
      .done { items in
        self.hasMore = items.count != 0
        self.items.append(contentsOf: items)
        self.delegate?.infinityScrollViewModelDidLoadMore(error: nil)
      }
      .catch { error in
        self.currentPage -= 1
        self.delegate?.infinityScrollViewModelDidLoadMore(error: error)
      }
      .finally {
        self.isFetching = false
    }
  }
}

protocol InfinityScrollViewModelDelegate: class {
  func infinityScrollViewModelWillReload()
  func infinityScrollViewModelDidReload(error: Error?)
  func infinityScrollViewModelWillLoadMore()
  func infinityScrollViewModelDidLoadMore(error: Error?)
}
