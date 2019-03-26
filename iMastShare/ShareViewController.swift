//
//  ShareViewController.swift
//  iMastShare
//
//  Created by rinsuki on 2017/06/07.
//  Copyright © 2017年 rinsuki. All rights reserved.
//

import UIKit
import Social
import Hydra
import SwiftyJSON
import Alamofire
import Fuzi
import MobileCoreServices

class ShareViewController: SLComposeServiceViewController {
    
    var isMastodonLogged = false
    var userToken = MastodonUserToken.getLatestUsed() {
        didSet {
            accountConfig.value = self.userToken!.acct
        }
    }
    var accountConfig = SLComposeSheetConfigurationItem()!
    var visibilityConfig = SLComposeSheetConfigurationItem()!
    var postUrl = ""
    var visibility = "public" {
        didSet {
            visibilityConfig.value = VisibilityLocalizedString[VisibilityString.firstIndex(of: visibility) ?? 0]
        }
    }
    var postMedia: [UploadableMedia] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Mastodonで共有"
        self.isMastodonLogged = self.userToken != nil
        if !self.isMastodonLogged {
            alertWithPromise(title: "エラー", message: "iMastにMastodonのアカウントが設定されていません。\niMastを起動してアカウントを登録してください。").then {
                self.cancel()
            }
            return
        }
        accountConfig.title = "アカウント"
        accountConfig.value = self.userToken!.acct
        accountConfig.tapHandler = {
            let VC = ShareAccountSelectorTableViewController()
            VC.nowUserTokenId = self.userToken!.id!
            VC.parentVC = self
            self.pushConfigurationViewController(VC)
        }
        visibilityConfig.title = "公開範囲"
        visibilityConfig.value = "公開"
        visibilityConfig.tapHandler = {
            let VC = ShareVisibilityTableViewController()
            VC.parentVC = self
            self.pushConfigurationViewController(VC)
        }

        let itemHandlers: [CFString: NSItemProvider.CompletionHandler] = [
            kUTTypeURL: self.processUrl,
            kUTTypeImage: self.processImage,
        ]

        for inputItem in self.extensionContext!.inputItems as! [NSExtensionItem] {
            for itemProvider in inputItem.attachments ?? [] {
                print(itemProvider)
                for (uti, handler) in itemHandlers {
                    if itemProvider.hasItemConformingToTypeIdentifier(uti as String) {
                        itemProvider.loadItem(forTypeIdentifier: uti as String, options: nil, completionHandler: handler)
                    }
                }
            }
        }
        self.validateContent()
    }
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        self.charactersRemaining = 500 - self.contentText.count - self.postUrl.count as NSNumber
        return Int(truncating: self.charactersRemaining) >= 0 && self.isMastodonLogged
    }
    
    func processUrl(item: NSSecureCoding?, error: Error?) {
        if let error = error {
            self.extensionContext!.cancelRequest(withError: error)
            return
        }
        guard var url = item as? NSURL else {
            return
        }
        if url.scheme == "file" {
            return
        }
        let query = urlComponentsToDict(url: url as URL)
        
        // Twitterトラッキングを蹴る
        if Defaults[.shareNoTwitterTracking] && url.host?.hasSuffix("twitter.com") ?? false {
            var urlComponents = URLComponents(string: url.absoluteString!)!
            urlComponents.queryItems = (urlComponents.queryItems ?? []).filter({$0.name != "ref_src"})
            if (urlComponents.queryItems ?? []).count == 0 {
                urlComponents.query = nil
            }
            let urlString = (urlComponents.url?.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))!
            url = NSURL(string: urlString)!
        }
        self.postUrl = url.absoluteString == nil ? "" : " "+url.absoluteString!
        
        // Twitter共有の引き継ぎ
        if url.host == "twitter.com" && url.path == "/intent/tweet" {
            var twitterPostText: String = ""
            if let text = query["text"] {
                twitterPostText += text
            }
            if let url = query["url"] {
                twitterPostText += " " + url
            }
            if let hashtags = query["hashtags"] {
                hashtags.components(separatedBy: ",").forEach { hashtag in
                    twitterPostText += " #" + hashtag
                }
            }
            if let via = query["via"] {
                twitterPostText += " https://twitter.com/\(via)さんから"
            }
            DispatchQueue.main.sync {
                self.textView.text = twitterPostText
                self.postUrl = ""
            }
        }
        
        // GPMなうぷれ対応
        if Defaults[.usingNowplayingFormatInShareGooglePlayMusicUrl],
            url.scheme == "https", url.host == "play.google.com",
            let path = url.path, path.starts(with: "/music/m/"),
            let objectId = path.pregMatch(pattern: "^/music/m/(.+)$").safe(1) {
            let previewUrl = "https://play.google.com/music/preview/\(objectId)"
            Alamofire.request(previewUrl).responseData { res in
                print(res)
                switch res.result {
                case .success(let data):
                    guard let doc = try? Fuzi.HTMLDocument(data: data) else {
                        print("GPMNowPlayingError: Fuzi.HTMLDocumentでパースに失敗")
                        return
                    }
                    guard let trackElement = doc.xpath("//*[@itemtype='http://schema.org/MusicRecording/PlayMusicTrack']").first else {
                        print("GPMNowPlayingError: PlayMusicTrackがなかった")
                        return
                    }
                    if trackElement.parent?["itemtype"] == "http://schema.org/MusicAlbum/PlayMusicAlbum" {
                        print("GPMNowPlayingError: parentがAlbum")
                        return
                    }
                    guard let title = trackElement.xpath("./*[@itemprop='name']").first?.stringValue else {
                        print("GPMNowPlayingError: nameがない")
                        return
                    }
                    let artist = trackElement.xpath("./*[@itemprop='byArtist']/*[@itemprop='name']").first?.stringValue
                    let albumTitle = trackElement.xpath("./*[@itemprop='inAlbum']/*[@itemprop='name']").first?.stringValue
                    let nowPlayingText = Defaults[.nowplayingFormat]
                        .replace("{title}", title)
                        .replace("{artist}", artist ?? "")
                        .replace("{albumTitle}", albumTitle ?? "")
                        .replace("{albumArtist}", "")
                    print(Thread.isMainThread)
                    DispatchQueue.mainSafeSync {
                        self.textView.text = nowPlayingText
                    }
                case .failure(let error):
                    print("GPMNowPlayingError: Failed fetch Information", error)
                }
            }
            print("GPMやないかーい", previewUrl)
        }
    }

    func processImage(item: NSSecureCoding?, error: Error?) {
        if let error = error {
            self.extensionContext!.cancelRequest(withError: error)
            return
        }
        if let imageData = item as? Data {
            self.postMedia.append(UploadableMedia(format: .png, data: imageData, url: nil, thumbnailImage: UIImage(data: imageData)!))
        } else if let imageUrl = item as? NSURL {
            print(imageUrl)
            if imageUrl.isFileURL, let data = try? Data(contentsOf: imageUrl as URL) {
                self.postMedia.append(UploadableMedia(format: (imageUrl.pathExtension ?? "").lowercased() == "png" ? .png : .jpeg, data: data, url: nil, thumbnailImage: UIImage(data: data)!))
            }
        } else if let image = item as? UIImage {
            self.postMedia.append(UploadableMedia(format: .png, data: image.pngData()!, url: nil, thumbnailImage: image))
        }
    }
    
    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        let alert = UIAlertController(title: "投稿中", message: "しばらくお待ちください", preferredStyle: UIAlertController.Style.alert)
        present(alert, animated: true, completion: nil)
        let promise: Promise<[JSON]> = async { status -> [JSON] in
            var results: [JSON] = []
            for medium in self.postMedia {
                let result = try await(self.userToken!.upload(file: medium.toUploadableData(), mimetype: medium.getMimeType()))
                if result["_response_code"].intValue >= 400 {
                    throw APIError.errorReturned(errorMessage: result["error"].stringValue, errorHttpCode: result["_response_code"].intValue)
                }
                if result["id"].exists() {
                    results.append(result)
                } else {
                    print(result)
                }
            }
            return results
        }
        promise.then { images in
            self.userToken!.post("statuses", params: [
                "status": self.contentText + self.postUrl,
                "visibility": self.visibility,
                "media_ids": images.map({ (media) -> JSON in
                    return media["id"]
                }),
            ]).then { res in
                alert.dismiss(animated: true)
                self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            }
        }.catch { (error) -> Void in
            alert.dismiss(animated: false)
            var promise: Promise<Void>!
            do {
                throw error
            } catch APIError.errorReturned(let errorMessage, let errorHttpCode) {
                promise = self.apiErrorWithPromise(errorMessage, errorHttpCode)
            } catch {
                promise = self.apiErrorWithPromise("未知のエラーが発生しました。\n\(error.localizedDescription)", -1001)
            }
            promise.then {
                self.extensionContext!.cancelRequest(withError: error)
            }
        }
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return [
            accountConfig,
            visibilityConfig,
        ]
    }
}
