//
//  HiddenNavbarViewController.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 13/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import UIKit

class HiddenNavbarTableViewController: UITableViewController { 
  private var oldTitleTextAttributes: [NSAttributedString.Key : Any]?
  private var oldBackgroundImage: UIImage?
  private var oldShadowImage: UIImage?
  private var oldIsTranslucent = false
  private var oldTintColor: UIColor?
  private var oldBarStyle: UIBarStyle = .default
  var headerHeight: CGFloat = 200
  
  private var navigationBarHidden = false
  private var viewIsVisible = false
  
  private func hideNavigationBar() {
    guard !navigationBarHidden else { return }
    
    navigationBarHidden = true
    
    oldTitleTextAttributes = navigationController!.navigationBar.titleTextAttributes
    oldBackgroundImage = navigationController!.navigationBar.backgroundImage(for: .default)
    oldShadowImage = navigationController!.navigationBar.shadowImage
    oldIsTranslucent = navigationController!.navigationBar.isTranslucent
    oldTintColor = navigationController!.navigationBar.tintColor
    oldBarStyle = navigationController!.navigationBar.barStyle
    
    navigationController!.navigationBar.barStyle = .black
    navigationController!.navigationBar.titleTextAttributes = [
      NSAttributedString.Key.foregroundColor: UIColor.clear
    ]
    navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
    navigationController!.navigationBar.shadowImage = UIImage()
    navigationController!.navigationBar.isTranslucent = true
    navigationController!.navigationBar.tintColor = .white
    
    let navigationBarHeight = navigationController!.navigationBar.frame.height
    let statusBarHeight = UIApplication.shared.statusBarFrame.height
    
    UIView.animate(withDuration: 0.2) {
      self.tableView.contentInset.top = -(navigationBarHeight + statusBarHeight)
    }
  }
  
  private func showNavigationBar() {
    guard navigationBarHidden else { return }
    
    navigationBarHidden = false
    
    navigationController!.navigationBar.barStyle = oldBarStyle
    navigationController!.navigationBar.titleTextAttributes = oldTitleTextAttributes
    navigationController!.navigationBar.setBackgroundImage(oldBackgroundImage, for: .default)
    navigationController!.navigationBar.shadowImage = oldShadowImage
    navigationController!.navigationBar.isTranslucent = oldIsTranslucent
    navigationController!.navigationBar.tintColor = oldTintColor
    
    UIView.animate(withDuration: 0.2) {
      self.tableView.contentInset.top = 0
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    viewIsVisible = true
    hideNavigationBar()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    viewIsVisible = false
    showNavigationBar()
  }
  
  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard viewIsVisible else { return }
    
    let navigationBarHeight = navigationController!.navigationBar.frame.height
    let statusBarHeight = UIApplication.shared.statusBarFrame.height
    
    if scrollView.contentOffset.y > (headerHeight - navigationBarHeight - statusBarHeight) {
      showNavigationBar()
    } else {
      hideNavigationBar()
    }
  }
}
