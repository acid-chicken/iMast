//
//  NotificationTableViewController.swift
//  iMast
//
//  Created by rinsuki on 2017/07/30.
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
import Mew
import iMastiOSCore

class NotificationTableViewController: UITableViewController, Instantiatable {
    typealias ExcludeTypes = [NotificationType]
    typealias Input = ExcludeTypes
    enum NotificationType: String, CaseIterable {
        case follow
        case favourite
        case reblog
        case mention
        case poll

        static func reverse(types: [Self]) -> [Self] {
            return Self.allCases.filter { !types.contains($0) }
        }
    }
    typealias Environment = MastodonUserToken

    internal let environment: Environment

    var notifications: [MastodonNotification] = []
    let readmoreCell = ReadmoreTableViewCell()

    required init(with input: Input, environment: Environment) {
        self.environment = environment
        request = .init(excludedTypes: input.map { $0.rawValue })
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let request: MastodonEndpoint.GetNotifications

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = R.string.localizable.notifications()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        // init refreshControl
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(self.refreshNotification), for: UIControl.Event.valueChanged)

        self.readmoreCell.state = .loading
        environment.request(ep: request).then { notifications in
            self.readmoreCell.state = notifications.count > 0 ? .moreLoadable : .allLoaded
            self.notifications = notifications
            self.tableView.reloadData()
        }.catch { error in
            self.readmoreCell.lastError = error
            self.readmoreCell.state = .withError
        }

        self.tableView.register(R.nib.notificationTableViewCell)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return notifications.count
        } else {
            return 1
        }
    }

    @objc func refreshNotification() {
        var req = request
        if let prevId = notifications.first?.id {
            req.paging = .prev(prevId.string, isSinceId: true)
        }
        environment.request(ep: req).then({ new_notifications in
            new_notifications.reversed().forEach({ (notify) in
                self.notifications.insert(notify, at: 0)
            })
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }).catch { error in
            self.errorReport(error: error)
            self.refreshControl?.endRefreshing()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.notificationTableViewCell, for: indexPath)!
            cell.load(notification: self.notifications[indexPath.row])
            return cell
        } else {
            return self.readmoreCell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let notification = self.notifications[indexPath.row]
            self.openNotify(notification)
        } else {
            // read more
            self.readmoreCell.readMoreTapped(viewController: self) {
                self.readMore()
            }
        }
    }

    var oldFetchedTime = Date.timeIntervalSinceReferenceDate
    var oldOffset: CGFloat = 0

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard Defaults[.notifyTabInfiniteScroll] else {
            return
        }
        let currentOffset = scrollView.contentOffset.y
        let maxOffset = scrollView.contentSize.height - scrollView.frame.height
        let diff = maxOffset - currentOffset
        var bottomHeight = scrollView.contentInset.bottom
        if #available(iOS 11.0, *) {
            bottomHeight = scrollView.adjustedContentInset.bottom
        }

        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
            let diffTrue = Int(diff + bottomHeight)
            print(diff, diffTrue, bottomHeight)
            let nowTime = Date.timeIntervalSinceReferenceDate

            let diffTime = nowTime - self.oldFetchedTime
            if diffTime > 0.1 {
                self.oldFetchedTime = nowTime
                let speed = currentOffset - self.oldOffset
                if speed > 10 {
                    let estOffset = diffTrue - Int(speed / CGFloat(diffTime)) // 1秒後も同じ速さでスクロールしていた場合の位置
                    print(estOffset)
                    if estOffset < 200 {
                        DispatchQueue.main.async {
                            self.readMore()
                        }
                    }
                }
                self.oldFetchedTime = nowTime
                self.oldOffset = currentOffset
            }

            if diffTrue < 200 {
                DispatchQueue.main.async {
                    self.readMore()
                }
            }
        }
    }

    func readMore() {
        guard self.readmoreCell.state == .moreLoadable else {
            return
        }

        self.readmoreCell.state = .loading
        var req = request
        req.limit = 40
        if let lastId = self.notifications.last?.id {
            req.paging = .next(lastId.string)
        }
        environment.request(ep: req).then { notifications in
            let oldCount = self.notifications.count
            self.notifications.append(contentsOf: notifications)
            self.tableView.beginUpdates()
            self.tableView.insertRows(at: (oldCount..<oldCount + notifications.count).map { IndexPath(row: $0, section: 0)}, with: .automatic)
            self.tableView.endUpdates()
            self.readmoreCell.state = notifications.count > 0 ? .moreLoadable : .allLoaded
        }.catch { error in
            self.readmoreCell.lastError = error
            self.readmoreCell.state = .withError
        }
    }

    func openNotify(_ notification: MastodonNotification, animated: Bool = true) {
        if let vc = NotificationTableViewController.getNotifyVC(notification, environment: environment) {
            navigationController?.pushViewController(vc, animated: animated)
        }
    }

    static func getNotifyVC(_ notification: MastodonNotification, environment: MastodonUserToken) -> UIViewController? {
        guard let account = notification.account else {
            return nil
        }
        if let status = notification.status { // 投稿つき
            switch notification.type {
            case "mention", "poll":
                return MastodonPostDetailViewController.instantiate(status, environment: environment)
            default:
                let newVC = PostAndUserViewController(with: ([status], [account]), environment: environment)
                newVC.title = [
                    "favourite": "ふぁぼられ",
                    "reblog": "ブースト",
                ][notification.type]
                return newVC
           }
        } else { // ユーザーつき
            return UserProfileTopViewController.instantiate(account, environment: environment)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
