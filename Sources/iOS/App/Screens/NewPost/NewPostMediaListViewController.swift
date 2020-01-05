//
//  NewPostMediaListViewController.swift
//  iMast
//
//  Created by rinsuki on 2018/04/21.
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
import MobileCoreServices
import AVFoundation
import AVKit
import Photos
import Hydra

class NewPostMediaListViewController: UIViewController {

    let newPostVC: NewPostViewController
    var transparentVC: UIViewController = TransparentViewController()

    @IBOutlet weak var imagesStackView: UIStackView!
    init(newPostVC: NewPostViewController) {
        self.newPostVC = newPostVC
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.refresh()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func refresh() {
        // update image select button title
        self.newPostVC.imageSelectButton.setTitle(" "+self.newPostVC.media.count.description, for: .normal)

        // update image list view
        for imageView in self.imagesStackView.arrangedSubviews {
            self.imagesStackView.removeArrangedSubview(imageView)
            imageView.removeFromSuperview()
        }
        if self.newPostVC.media.count > 0 {
            for (index, media) in self.newPostVC.media.enumerated() {
                let imageView = UIImageView(image: media.thumbnailImage)
                imageView.ignoreSmartInvert()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.tag = index
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapCurrentMedia(sender:)))
                tapGesture.numberOfTapsRequired = 1
                imageView.isUserInteractionEnabled = true
                imageView.addGestureRecognizer(tapGesture)
                self.imagesStackView.addArrangedSubview(imageView)
            }
        } else {
            let label = UILabel()
            label.textColor = .secondaryLabel
            label.text = "← から画像を追加"
            self.imagesStackView.addArrangedSubview(label)
        }
        self.imagesStackView.setNeedsLayout()
        self.imagesStackView.layoutIfNeeded()
    }

    func addMedia(media: UploadableMedia) {
        // TODO
        self.newPostVC.media.append(media)
        self.refresh()
    }

    @IBAction func tapAddImage(_ sender: UIButton) {
        let pickerSelector = CustomDocumentMenuViewController(
            documentTypes: [
                "public.image",
            ],
            in: UIDocumentPickerMode.import
        )
        pickerSelector.popoverPresentationController?.sourceView = sender
        pickerSelector.popoverPresentationController?.sourceRect = sender.frame
        pickerSelector.popoverPresentationController?.delegate = self
        pickerSelector.delegate = self
        pickerSelector.addOption(withTitle: "フォトライブラリ", image: UIImage(systemName: "photo.on.rectangle"), order: .first, handler: {
            print("photo-library")
            let imgPickerC = UIImagePickerController()
            print(imgPickerC.modalPresentationStyle.rawValue)
            imgPickerC.sourceType = UIImagePickerController.SourceType.photoLibrary
            if #available(iOS 11.0, *) {
                imgPickerC.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
                imgPickerC.videoExportPreset = AVAssetExportPresetPassthrough
            }
            imgPickerC.delegate = self
            self.transparentVC.dismiss(animated: false, completion: nil)
            self.present(imgPickerC, animated: true, completion: nil)
        })
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            pickerSelector.addOption(withTitle: "写真を撮る", image: UIImage(systemName: "camera.fill"), order: .first, handler: {
                print("camera")
                let imgPickerC = UIImagePickerController()
                imgPickerC.sourceType = UIImagePickerController.SourceType.camera
                imgPickerC.delegate = self
                self.transparentVC.dismiss(animated: false, completion: nil)
                self.present(imgPickerC, animated: true, completion: nil)
            })
        }
        pickerSelector.delegate = self
        self.transparentVC.modalPresentationStyle = .overFullScreen
        pickerSelector.parentVC = self.transparentVC
        pickerSelector.popoverPresentationController?.permittedArrowDirections = .down
        self.present(self.transparentVC, animated: true) {
            self.transparentVC.present(pickerSelector, animated: true, completion: nil)
        }
    }

    @objc func tapCurrentMedia(sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        let media = newPostVC.media[index]

        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "プレビュー", style: .default, handler: { _ in
            switch media.format {
            case .png, .jpeg:
                let viewController = UIViewController()
                let imageView = UIImageView()
                imageView.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
                imageView.image = UIImage(data: media.data)
                imageView.ignoreSmartInvert()
                imageView.contentMode = .scaleAspectFit
                viewController.view = imageView
                let closeGesture = UITapGestureRecognizer(target: viewController, action: #selector(viewController.close))
                imageView.isUserInteractionEnabled = true
                imageView.addGestureRecognizer(closeGesture)
                self.present(viewController, animated: true, completion: nil)
            case .mp4:
                guard let url = media.url else {
                    return
                }
                let viewController = AVPlayerViewController()
                viewController.player = AVPlayer(url: url)
                self.present(viewController, animated: true, completion: nil)
            }
        }))
        alertVC.addAction(UIAlertAction(title: "削除", style: .destructive, handler: { _ in
            self.newPostVC.media.remove(at: index)
            self.refresh()
        }))
        alertVC.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))

        self.present(alertVC, animated: true, completion: nil)
    }
}

private class TransparentViewController: UIViewController {
    override func viewDidLoad() {
        let touchGesture = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        touchGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(touchGesture)
    }

    @objc func onTapped() {
        alertWithPromise(title: "内部エラー", message: "このダイアログはでないはずだよ\n(loc: TransparentViewController.viewDidLoad.touchGesture)").then {
            self.dismiss(animated: false, completion: nil)
        }
    }
}

private class CustomDocumentMenuViewController: UIDocumentMenuViewController {
    var parentVC: UIViewController?
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: {
            if let parentVC = self.parentVC {
                if parentVC.modalPresentationStyle == .overFullScreen {
                    parentVC.dismiss(animated: false, completion: completion)
                }
            } else {
                completion?()
            }
        })
    }
}

extension NewPostMediaListViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        self.transparentVC.dismiss(animated: false, completion: nil)
    }
}

extension NewPostMediaListViewController: UIDocumentPickerDelegate {
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        self.transparentVC.dismiss(animated: true, completion: nil)
        self.present(documentPicker, animated: true, completion: nil)
    }
}

extension NewPostMediaListViewController: UIDocumentMenuDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let data = try! Data(contentsOf: url, options: NSData.ReadingOptions.mappedIfSafe)
        self.addMedia(media: UploadableMedia(format: url.pathExtension.lowercased() == "png" ? .png : .jpeg, data: data, url: nil, thumbnailImage: UIImage(data: data)!))
    }
}

extension NewPostMediaListViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        print(info)
        if let url = info[.imageURL] as? URL {
            let data = try! Data(contentsOf: url, options: NSData.ReadingOptions.mappedIfSafe)
            self.addMedia(media: UploadableMedia(format: url.pathExtension.lowercased() == "png" ? .png : .jpeg, data: data, url: nil, thumbnailImage: UIImage(data: data)!))
        } else if let url = info[.mediaURL] as? URL {
            async(in: .background) {
                let asset = AVURLAsset(url: url)
                // サムネイルを作る
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                let cgImage = try! imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
                let thumbnailImage = UIImage(cgImage: cgImage)
                // H.264でなかったら再エンコードが必要
                // (H.265とかでもSafariなら見られるがみんなChrome使ってるので...)
                var requiredReEncoding = false
                if let videoTrack = asset.tracks(withMediaType: .video).first {
                    let formats = videoTrack.formatDescriptions as! [CMFormatDescription]
                    for (index, formatDesc) in formats.enumerated() {
                        let type = CMFormatDescriptionGetMediaType(formatDesc).toString()
                        guard type == "vide" else { continue }
                        let format = CMFormatDescriptionGetMediaSubType(formatDesc).toString()
                        guard type != "avc1" else { continue }
                        // H.264じゃないので再エンコードが必要
                        requiredReEncoding = true
                    }
                }
                let RE_ENCODING_BORDER = 40 * 1000 * 1000 // 40MB
                // 40MB越えてたら再エンコ
                if let attr = try? FileManager.default.attributesOfItem(atPath: url.path) as NSDictionary, attr.fileSize() >= RE_ENCODING_BORDER {
                    requiredReEncoding = true
                }
                // mp4にコンテナ交換
                let exportSession = AVAssetExportSession(asset: asset, presetName: requiredReEncoding ? AVAssetExportPreset1280x720 : AVAssetExportPresetPassthrough)!
                let outUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".mp4")
                print(outUrl)
                exportSession.outputFileType = AVFileType.mp4
                exportSession.outputURL = outUrl
                exportSession.shouldOptimizeForNetworkUse = true
                exportSession.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
                if exportSession.estimatedOutputFileLength >= RE_ENCODING_BORDER {
                    guard try! await(self.confirm(
                        title: "確認",
                        message: "動画をこのままエンコードすると40MBを越えそうです(予想される出力ファイルサイズ: \(exportSession.estimatedOutputFileLength)bytes)。このままエンコードしますか?",
                        okButtonMessage: "OK",
                        style: .default,
                        cancelButtonMessage: "キャンセル"
                    )) else { return }
                }
                let alert = DispatchQueue.mainSafeSync {
                    UIAlertController(title: "動画の処理中", message: "しばらくお待ちください", preferredStyle: .alert)
                }
                try! await(self.presentPromise(alert, animated: true))
                let timer = DispatchQueue.mainSafeSync {
                    Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true, block: { _ in
                        alert.message = "しばらくお待ちください (\(String(format: "%.1f", arguments: [exportSession.progress * 100.0]))%, est: \(exportSession.estimatedOutputFileLength))"
                    })
                }
                try! await(exportSession.exportPromise())
                timer.invalidate()
//                    print((try? FileManager.default.attributesOfItem(atPath: outUrl.path)))
                let data = try! Data(contentsOf: outUrl)
                DispatchQueue.mainSafeSync {
                    alert.dismiss(animated: true, completion: nil)
                    self.addMedia(media: UploadableMedia(format: .mp4, data: data, url: outUrl, thumbnailImage: thumbnailImage))
                }
            }
            return
        } else if let assetUrl = info[.referenceURL] as? URL {
            #if !targetEnvironment(macCatalyst)
                let assets = PHAsset.fetchAssets(withALAssetURLs: [assetUrl], options: nil)
                guard let asset = assets.firstObject else {
                    self.alert(title: "エラー", message: "failed to fetch assets")
                    return
                }
                if asset.mediaType == .image {
                    PHImageManager.default().requestImageData(for: asset, options: nil) { (data, dataUTI, orientation, info) in
                        guard let data = data else {
                            self.alert(title: "エラー", message: "failed to fetch data from PHImageManager")
                            return
                        }
                        self.addMedia(media: UploadableMedia(format: dataUTI == "public.jpeg" ? .jpeg : .png, data: data, url: nil, thumbnailImage: UIImage(data: data)!))
                    }
                } else {
                    self.alert(title: "エラー", message: "unknown mediaType: \(asset.mediaType.rawValue)")
                }
            #else
                self.alert(title: "エラー", message: "Mac版ではこの機能は利用できません")
                return
            #endif
        } else if let image = info[.originalImage] as? UIImage {
            // たぶんここに来るやつはカメラなので適当にjpeg圧縮する
            guard let data = image.jpegData(compressionQuality: 1) else {
                self.alert(title: "エラー", message: "failed to jpeg encode")
                return
            }
            self.addMedia(media: UploadableMedia(format: .jpeg, data: data, url: nil, thumbnailImage: image))
        } else {
            self.alert(title: "エラー", message: "image is nil(loc: NewPostMediaListViewController.imagePickerController)")
            return
        }
    }
}

extension NewPostMediaListViewController: UINavigationControllerDelegate {
}
