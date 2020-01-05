//
//  BunmyakuTableViewController.swift
//  iMast
//
//  Created by rinsuki on 2019/07/03.
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
//

import UIKit
import Hydra
import iMastiOSCore

class BunmyakuTableViewController: TimeLineTableViewController {
    var basePost: MastodonPost!

    override func viewDidLoad() {
        self.isReadmoreEnabled = false
        self.isRefreshEnabled = false
        super.viewDidLoad()
        self.title = "文脈"
    }

    override func loadTimeline() -> Promise<()> {
        self.readmoreCell.state = .loading
        return environment.context(post: self.basePost).then { res in
            self.readmoreCell.state = .moreLoadable
            self._addNewPosts(posts: res.ancestors + [self.basePost] + res.descendants)
        }.catch { e in
            self.readmoreCell.state = .withError
            self.readmoreCell.lastError = e
        }
    }
}
