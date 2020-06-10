//
//  AppDelegate.swift
//  Search Book
//
//  Created by Petrus on 7/8/19.
//  Copyright © 2019 Petrus Nguyễn Thái Học. All rights reserved.
//

import UIKit
import SwinjectStoryboard
import SwinjectAutoregistration

extension SwinjectStoryboard {
  @objc class func setup() {
    let container = self.defaultContainer

    // MARK: - ViewController

    container.storyboardInitCompleted(HomeVC.self) { resolver, controller in
      controller.homeVM = resolver ~> HomeVM.self
    }

    container.storyboardInitCompleted(DetailVC.self) { resolver, controller in
      controller.detailVM = resolver ~> DetailVM.self
    }

    container.storyboardInitCompleted(FavoritesVC.self) { resolver, controller in
      controller.favoritesVM = resolver ~> FavoritesVM.self
    }

    // MARK: - Domain

    container
      .register(BookRepository.self) { resolver in
        BookRepositoryImpl(bookApi: resolver ~> BookApi.self)
      }
      .inObjectScope(.container)

    container
      .register(FavoritedBooksRepository.self) { resolver in
        FavoritedBooksRepositoryImpl(userDefaults: resolver ~> UserDefaults.self)
      }
      .inObjectScope(.container)

    // MARK: - Data

    container
      .autoregister(BookApi.self, initializer: BookApi.init)
      .inObjectScope(.container)

    container
      .register(UserDefaults.self) { _ in UserDefaults.standard }
      .inObjectScope(.container)

    // MARK: - ViewModels

    container
      .register(HomeInteractor.self) { resolver in
        HomeInteractorImpl(
          bookRepository: resolver ~> BookRepository.self,
          favoritedBooksRepository: resolver ~> FavoritedBooksRepository.self
        )
      }
      .inObjectScope(.transient)

    container
      .autoregister(HomeVM.self, initializer: HomeVM.init(homeInteractor:))
      .inObjectScope(.transient)

    container
      .register(DetailInteractor.self) { resolver in
        DetailInteractorImpl(
          bookRepository: resolver ~> BookRepository.self,
          favBookRepo: resolver ~> FavoritedBooksRepository.self
        )
      }
      .inObjectScope(.transient)

    container
      .autoregister(DetailVM.self, initializer: DetailVM.init(detailInteractor:))
      .inObjectScope(.transient)

    container
      .register(FavoritesInteractor.self) { resolver in
        FavoritesInteractorImpl(
          favBooksRepo: resolver ~> FavoritedBooksRepository.self,
          booksRepo: resolver ~> BookRepository.self
        )
      }
      .inObjectScope(.transient)

    container
      .autoregister(FavoritesVM.self, initializer: FavoritesVM.init(detailInteractor:))
      .inObjectScope(.transient)
  }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?


  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

