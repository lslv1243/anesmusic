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
  let imageUrl: String
}

struct AlbumItem {
  let name: String
  let coverUrl: String
}

class ApiClient {
  private let apiKey: String
  private let pageSize = 50
  
  init(apiKey: String) {
    self.apiKey = apiKey
  }
  
  private let decoder = JSONDecoder()
  
  func getTopGenres() -> Promise<[GenreItem]> {
    struct Response: Decodable {
      let toptags: TopTags
      
      struct TopTags: Decodable {
        let tag: [Tag]
      }
      
      struct Tag: Decodable {
        let name: String
      }
    }
    
    let url = "https://ws.audioscrobbler.com/2.0/?method=tag.getTopTags&api_key=\(apiKey)&format=json"
    
    return Alamofire.request(url)
      .responseData()
      .map { response in
        let data = try! self.decoder.decode(Response.self, from: response.data)
        return data.toptags.tag.map { GenreItem(name: $0.name) }
      }
  }
  
  func getTopArtists(genre: String, page: Int) -> Promise<[ArtistItem]> {
    struct Response: Decodable {
      let topartists: TopArtists
      
      struct TopArtists: Decodable {
        let artist: [Artist]
      }
      
      struct Artist: Decodable {
        let name: String
        let mbid: String?
        let image: [Image]
      }
      
      typealias Image = Dictionary<String, String>
    }
    
    let genreUrl = genre.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    let url = "https://ws.audioscrobbler.com/2.0/?method=tag.gettopartists&tag=\(genreUrl)&api_key=\(apiKey)&format=json&limit=\(pageSize)&page=\(page)"
    
    return Alamofire.request(url)
      .responseData()
      .map { response in
        let data = try! self.decoder.decode(Response.self, from: response.data)
        return data.topartists.artist.compactMap { artist in
          // some artists don't have the attribute "mbid", they can't be used to query for albums
          guard let mbid = artist.mbid else { return nil }
          return ArtistItem(
            id: mbid,
            name: artist.name,
            imageUrl: artist.image[1]["#text"]!
          )
        }
      }
  }
  
  func getTopAlbums(artistId: String, page: Int) -> Promise<[AlbumItem]> {
    struct Response: Decodable {
      let topalbums: TopAlbums
      
      struct TopAlbums: Decodable {
        let album: [Album]
      }
      
      struct Album: Decodable {
        let name: String
        let image: [Image]
      }
      
      typealias Image = Dictionary<String, String>
    }
    
    let url = "https://ws.audioscrobbler.com/2.0/?method=artist.gettopalbums&mbid=\(artistId)&api_key=\(apiKey)&format=json&limit=\(pageSize)&page=\(page)"
    
    return Alamofire.request(url)
      .responseData()
      .map { response in
        let data = try! self.decoder.decode(Response.self, from: response.data)
        return data.topalbums.album.map { AlbumItem(
          name: $0.name,
          coverUrl: $0.image[1]["#text"]!
        ) }
      }
  }
}
