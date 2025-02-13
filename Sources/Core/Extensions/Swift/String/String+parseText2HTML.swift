//
//  String+parseText2HTML.swift
//  iMast
//
//  Created by rinsuki on 2018/09/20.
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
import Fuzi
import Hydra
import SDWebImage

#if os(macOS)
typealias NSUIFont = NSFont
#else
typealias NSUIFont = UIFont
#endif

extension String {
    public func parseText2HTMLNew(attributes: [NSAttributedString.Key: Any], asyncLoadProgressHandler: (() -> Void)? = nil) -> NSAttributedString? {
        do {
            let document = try Fuzi.HTMLDocument(string: self)
            guard let root = document.root?.children(staticTag: "body").first else {
                print("empty root")
                return NSAttributedString(string: "")
            }
            
            let fetchNodeTypes: [Fuzi.XMLNodeType] = [
                .Text,
                .Element,
            ]
            
            func generateAttrStr(attributes: [NSAttributedString.Key: Any], nodes: [Fuzi.XMLNode]) -> (NSMutableAttributedString, [Promise<Void>]) {
                var promises: [Promise<Void>] = []
                let attrStr = NSMutableAttributedString(string: "")
                for node in nodes {
                    switch node.type {
                    case .Text:
                        attrStr.append(NSAttributedString(string: node.stringValue, attributes: attributes))
                    case .Element:
                        var attrs = attributes
                        if let element = node.toElement() {
                            let tagName = element.tag?.lowercased() ?? ""
                            // タグ前処理
                            switch tagName {
                            case "a":
                                if let href = element.attributes["href"]?.addingPercentEncoding(withAllowedCharacters: CharacterSet.init(charactersIn: Unicode.Scalar(0)...Unicode.Scalar(0x7f))) {
                                    attrs[.link] = href
                                    attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
                                }
                            case "strong", "b":
                                let font = (attrs[.font] as? NSUIFont) ?? NSUIFont.systemFont(ofSize: NSUIFont.systemFontSize)
                                #if os(macOS)
                                let newFont = NSUIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.bold), size: font.pointSize)
                                attrs[.font] = newFont
                                #else
                                if let fontDescriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) {
                                    let newFont = NSUIFont(descriptor: fontDescriptor, size: font.pointSize)
                                    attrs[.font] = newFont
                                }
                                #endif
                            default:
                                break
                            }
                            
                            var (childAttrStr, childPromises) = generateAttrStr(attributes: attrs, nodes: element.childNodes(ofTypes: fetchNodeTypes))
                            promises += childPromises
                            
                            // タグ後処理
                            if let tagName = element.tag?.lowercased() {
                                switch tagName {
                                case "br":
                                    childAttrStr.append(NSAttributedString(string: "\n", attributes: attrs))
                                case "p":
                                    childAttrStr.append(NSAttributedString(string: "\n\n", attributes: attrs))
                                #if !os(macOS)
                                case "img":
                                    if let src = element.attributes["src"], let srcUrl = URL(string: src) {
                                        let attachment = NSTextAttachment()
                                        let font = attributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: CGFloat(Defaults.timelineTextFontsize))
                                        let size = font.lineHeight + 1
                                        attachment.bounds = CGRect(x: 0, y: 0, width: size, height: size)
                                        attachment.bounds.origin = CGPoint(x: 0, y: -4)
                                        childAttrStr = NSMutableAttributedString(attachment: attachment)
                                        if asyncLoadProgressHandler == nil {
                                            if let srcData = try? Data(contentsOf: srcUrl) {
                                                attachment.image = UIImage(data: srcData)
                                            }
                                        } else {
                                            let promise = Promise<Void>(in: .background) { res, rej, _ in
                                                SDWebImageManager.shared.loadImage(with: srcUrl, options: [], progress: nil, completed: { (image, _, _, _, finished, _) in
                                                    if let image = image {
                                                        attachment.image = image
                                                        res(())
                                                    }
                                                })
                                            }
                                            promises.append(promise)
                                        }
                                    }
                                #endif
                                default:
                                    break
                                }
                            }
                            attrStr.append(childAttrStr)
                        }
                    default:
                        print("unknown node.type", node.type)
                    }
                }
                return (attrStr, promises)
            }
            
            let (attrStr, promises) = generateAttrStr(attributes: attributes, nodes: root.childNodes(ofTypes: fetchNodeTypes))
            if promises.count > 0 {
                if let asyncLoadProgressHandler = asyncLoadProgressHandler {
                    for promise in promises {
                        promise.then { asyncLoadProgressHandler() }
                    }
                } else {
                    print("WARNING: promises.count is not 0(\(promises.count)), but asyncLoadProgressHandler is nil. This is a bug.")
                }
            }
            var count = 0
            for char in attrStr.string.reversed() {
                if char == "\n" {
                    count += 1
                } else {
                    break
                }
            }
            attrStr.deleteCharacters(in: NSRange(location: attrStr.length - count, length: count))
            return attrStr
        } catch let error {
            print("failed to parse in new parser", error)
            return nil
        }
    }
    
    public func parseText2HTML(attributes: [NSAttributedString.Key: Any] = [:], asyncLoadProgressHandler: (() -> Void)? = nil) -> NSAttributedString? {
        #if os(macOS)
        return parseText2HTMLNew(attributes: attributes, asyncLoadProgressHandler: asyncLoadProgressHandler)
        #else
        if Defaults.newHtmlParser, let newParserResult = self.parseText2HTMLNew(attributes: attributes, asyncLoadProgressHandler: asyncLoadProgressHandler) {
            return newParserResult
        }
        if !self.replacingOccurrences(of: "<p>", with: "").replacingOccurrences(of: "</p>", with: "").contains("<") {
            return nil
        }
        
        // 受け取ったデータをUTF-8エンコードする
        let encodeData = self.data(using: String.Encoding.utf8, allowLossyConversion: true)
        
        // 表示データのオプションを設定する
        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html,
            NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue,
        ]
        
        // 文字列の変換処理
        let attributedString = try? NSMutableAttributedString(
            data: encodeData!,
            options: attributedOptions,
            documentAttributes: nil
        )
        attributedString?.addAttributes(attributes, range: NSRange(location: 0, length: attributedString?.length ?? 0))
        return attributedString
        #endif
    }
}
