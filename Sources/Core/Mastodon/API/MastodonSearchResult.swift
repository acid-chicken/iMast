//
//  MastodonSearchResult.swift
//  iMast
//
//  Created by rinsuki on 2018/01/10.
//  
//  ------------------------------------------------------------------------
//
//  Copyright 2017-2019 rinsuki and other contributors.
// 
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import Hydra

public struct MastodonSearchResultHashtag: Codable {
    public let name: String
    
    public init(from decoder: Decoder) throws {
        do {
            name = try decoder.container(keyedBy: CodingKeys.self).decode(String.self, forKey: .name)
        } catch {
            name = try decoder.singleValueContainer().decode(String.self)
        }
    }
}

extension MastodonSearchResultHashtag: Hashable {
    
}

public struct MastodonSearchResult: Codable, MastodonEndpointResponse {
    public let accounts: [MastodonAccount]
    public let posts: [MastodonPost]
    public let hashtags: [MastodonSearchResultHashtag]
    enum CodingKeys: String, CodingKey {
        case accounts
        case posts = "statuses"
        case hashtags
    }
}

extension MastodonUserToken {
    public func search(q: String, resolve: Bool = true) -> Promise<MastodonSearchResult> {
        return getIntVersion().then { ver in
            let req = MastodonEndpoint.Search(
                q: q, resolve: resolve,
                version: ver < MastodonVersionStringToInt("2.4.1") ? .v1 : .v2
            )
            return req.request(with: self)
        }
    }
}

extension MastodonEndpoint {
    public struct Search: MastodonEndpointProtocol {
        public typealias Response = MastodonSearchResult
        
        public var endpoint: String { "/api/\(version.rawValue)/search" }
        public let method = "GET"
        
        public var query: [URLQueryItem] {
            return [
                .init(name: "q", value: q),
                .init(name: "resolve", value: resolve ? "true" : "false"),
            ]
        }
        
        public var q: String
        public var resolve: Bool = true
        public var version: Version
        
        public enum Version: String {
            case v1
            case v2
        }
    }
}
