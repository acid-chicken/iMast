//
//  LocalTimelineViewController.swift
//  iMast
//
//  Created by rinsuki on 2017/05/24.
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

import UIKit
import SwiftyJSON
import Hydra

class LocalTimelineViewController: TimelineViewController {
    override func viewDidLoad() {
        self.timelineType = .local
        self.navigationItem.title = L10n.Localizable.localTimeline
        self.isNewPostAvailable = true
        super.viewDidLoad()
    }
    
    override func websocketEndpoint() -> String? {
        return "public:local"
    }
}
