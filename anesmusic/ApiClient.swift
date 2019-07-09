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

struct Genre {
  let name: String
}

struct Artist {
  let id: String
  let name: String
  let genre: String
  let imageUrl: String
}

struct Album {
  let name: String
  let genre: String
  let year: String
  let coverUrl: String
}

class ApiClient {
  private let apiKey = "93e9a520b0bd3e64a3a0d1be9c2cd5ea"
  private let pageSize = 20
  
  private let decoder = JSONDecoder()
  
  func getGenres(page: Int) -> Promise<[Genre]> {
    struct Response: Decodable {
      let toptags: TopTags
      
      struct TopTags: Decodable {
        let tag: [Tag]
      }
      
      struct Tag: Decodable {
        let name: String
      }
    }
    
    let url = "https://ws.audioscrobbler.com/2.0/?method=tag.getTopTags&api_key=\(apiKey)&format=json&limit=\(pageSize)&page=\(page)"
    
    return Alamofire.request(url)
      .responseData()
      .map { response in
        let data = try! self.decoder.decode(Response.self, from: response.data)
        return data.toptags.tag.map { Genre(name: $0.name) }
      }
  }
  
  func getArtists(genre: String, page: Int) -> Promise<[Artist]> {
    struct Response: Decodable {
      let topartists: TopArtists
      
      struct TopArtists: Decodable {
        let artist: [Artist]
      }
      
      struct Artist: Decodable {
        let name: String
        let mbid: String
        let image: [Image]
      }
      
      typealias Image = Dictionary<String, String>
    }
    
    let url = "https://ws.audioscrobbler.com/2.0/?method=tag.gettopartists&tag=\(genre)&api_key=\(apiKey)&format=json&limit=\(pageSize)&page=\(page)"
    
    return Alamofire.request(url)
      .responseData()
      .map { response in
        let data = try! self.decoder.decode(Response.self, from: response.data)
        return data.topartists.artist.map { Artist(
          id: $0.mbid,
          name: $0.name,
          genre: genre,
          imageUrl: $0.image[4]["#text"]!
        ) }
      }
  }
  
  func getAlbums(artistId: String, page: Int) -> Promise<[Album]> {
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
    
    let url = "http://ws.audioscrobbler.com/2.0/?method=artist.gettopalbums&mbid=\(artistId)&api_key=\(apiKey)&format=json&limit=\(pageSize)&page=\(page)"
    
    return Alamofire.request(url)
      .responseData()
      .map { response in
        let data = try! self.decoder.decode(Response.self, from: response.data)
        return data.topalbums.album.map { Album(
          name: $0.name,
          genre: "-",
          year: "-",
          coverUrl: $0.image[3]["#text"]!
          ) }
      }
  }
}
