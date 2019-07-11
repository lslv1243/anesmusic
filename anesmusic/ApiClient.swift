//
//  ApiClient.swift
//  anesmusic
//
//  Created by Leonardo da Silva on 08/07/19.
//  Copyright © 2019 Leonardo da Silva. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import PMKAlamofire

struct GenreItem {
  let name: String
}

struct ArtistItem {
  let id: String
  let name: String
  let imageUrl: String?
}

struct ArtistInfo {
  let id: String
  let name: String
  let imageUrl: String
  let genres: [GenreItem]
}

struct AlbumItem {
  let id: String
  let name: String
  let coverUrl: String
}

class ApiClient {
  private let decoder = JSONDecoder()
  private let authenticator: ApiClientAuthenticator
  
  private let pageSize = 30
  
  init(clientId: String, clientSecret: String) {
    authenticator = ApiClientAuthenticator(
      clientId: clientId,
      clientSecret: clientSecret
    )
  }
  
  func getTopGenres(page: Int) -> Promise<[GenreItem]> {
    return authenticator.getAccessToken()
      .then { accessToken -> Promise<[GenreItem]> in
        let url = "https://api.spotify.com/v1/browse/categories?limit=\(self.pageSize)&offset=\(self.pageSize * page)"
        
        var headers = HTTPHeaders()
        headers["Authorization"] = "Bearer \(accessToken)"
        
        struct Response: Decodable {
          let categories: Categories
          
          struct Categories: Decodable {
            let items: [Category]
          }
          
          struct Category: Decodable {
            let name: String
          }
        }
        
        return Alamofire
          .request(
            url,
            method: .get,
            headers: headers
          )
          .responseData()
          .map { response in
            let data = try! self.decoder.decode(Response.self, from: response.data)
            return data.categories.items.map { category in
              return GenreItem(name: category.name)
            }
        }
      }
  }
  
  func getTopArtists(genre: String, page: Int) -> Promise<[ArtistItem]> {
    return authenticator.getAccessToken()
      .then { accessToken -> Promise<[ArtistItem]> in
        let genreUrl = genre.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = "https://api.spotify.com/v1/search?q=genre:\(genreUrl)&type=artist&limit=\(self.pageSize)&offset=\(self.pageSize * page)"
       
        var headers = HTTPHeaders()
        headers["Authorization"] = "Bearer \(accessToken)"
        
        struct Response: Decodable {
          let artists: Artists
          
          struct Artists: Decodable {
            let items: [Item]
          }
          
          struct Item: Decodable {
            let id: String
            let name: String
            let images: [Image]
          }
          
          struct Image: Decodable {
            let url: String
          }
        }
        
        return Alamofire
          .request(
            url,
            method: .get,
            headers: headers
          )
          .responseData()
          .map { response in
            let data = try! self.decoder.decode(Response.self, from: response.data)
            return data.artists.items.map { item in
              return ArtistItem(
                id: item.id,
                name: item.name,
                imageUrl: item.images.last?.url
              )
            }
          }
      }
  }
  
  func getTopAlbums(artistId: String, page: Int) -> Promise<[AlbumItem]> {
    return authenticator.getAccessToken()
      .then { accessToken -> Promise<[AlbumItem]> in
        let url = "https://api.spotify.com/v1/artists/\(artistId)/albums?limit=\(self.pageSize)&offset=\(self.pageSize * page)"
        
        var headers = HTTPHeaders()
        headers["Authorization"] = "Bearer \(accessToken)"
        
        struct Response: Decodable {
          let items: [Item]
          
          struct Item: Decodable {
            let id: String
            let images: [Image]
            let name: String
          }
          
          struct Image: Decodable {
            let url: String
          }
        }
        
        return Alamofire
          .request(
            url,
            method: .get,
            headers: headers)
          .responseData()
          .map { response in
            let data = try! self.decoder.decode(Response.self, from: response.data)
            return data.items.map { item in
              return AlbumItem(
                id: item.id,
                name: item.name,
                coverUrl: item.images.last!.url
              )
            }
          }
      }
  }
  
  func getInfo(artistId: String) -> Promise<ArtistInfo> {
    return Promise.value(ArtistInfo(id: "", name: "", imageUrl: "", genres: []))
//    struct Response: Decodable {
//      let artist: Artist
//
//      struct Artist: Decodable {
//        let name: String
//        let mbid: String
//        let image: [Image]
//        let tags: Tags
//      }
//
//      typealias Image = Dictionary<String, String>
//
//      struct Tags: Decodable {
//        let tag: [Tag]
//      }
//
//      struct Tag: Decodable {
//        let name: String
//      }
//    }
//
//    let url = "https://ws.audioscrobbler.com/2.0/?method=artist.getinfo&mbid=\(artistId)&api_key=\(apiKey)&format=json"
//
//    return Alamofire.request(url)
//      .responseData()
//      .map { response in
//        let data = try! self.decoder.decode(Response.self, from: response.data)
//        return ArtistInfo(
//          id: data.artist.mbid,
//          name: data.artist.name,
//          imageUrl: data.artist.image[3]["#text"]!,
//          genres: data.artist.tags.tag.map { GenreItem(name: $0.name) }
//        )
//    }
  }
}

class ApiClientAuthenticator {
  private let decoder = JSONDecoder()
  let clientId: String
  let clientSecret: String
  private var accessToken: String?
  private var accessTokenExpiresAt = Date()
  
  init(clientId: String, clientSecret: String) {
    self.clientId = clientId
    self.clientSecret = clientSecret
  }
  
  func getAccessToken() -> Promise<String> {
    if accessToken != nil {
      if Date() > accessTokenExpiresAt {
        accessToken = nil
      }
    }
    
    if let accessToken = accessToken {
      return Promise.value(accessToken)
    }
    
    return authenticate().map { _ in self.accessToken! }
  }
  
  private func authenticate() -> Promise<Void> {
    let url = "https://accounts.spotify.com/api/token"
    
    let token = Data("\(clientId):\(clientSecret)".utf8).base64EncodedString()
    let headers: HTTPHeaders = ["Authorization": "Basic \(token)"]
    let parameters: Parameters = ["grant_type": "client_credentials"]
    
    struct Response: Decodable {
      let access_token: String
      let token_type: String
      let expires_in: Int
    }
    
    return Alamofire
      .request(
        url,
        method: .post,
        parameters: parameters,
        headers: headers
      )
      .responseData()
      .map { response in
        let data = try! self.decoder.decode(Response.self, from: response.data)
        self.accessToken = data.access_token
        self.accessTokenExpiresAt = Date() + TimeInterval(data.expires_in)
    }
  }
}
