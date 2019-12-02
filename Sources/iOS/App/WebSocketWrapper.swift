//
//  WebSocketWrapper.swift
//  iMast
//
//  Created by rinsuki on 2017/12/29.
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
import Starscream
import Hydra
import iMastiOSCore

var webSockets: [WebSocketWrapper] = []

class WebSocketWrapper: WebSocketDelegate {
    
    let webSocket: WebSocket
    var reconnect: Bool = true
    var reconnectWait: Int8 = 0
    weak var delegate: WebSocketWrapperDelegate?
    
    init(webSocket: WebSocket) {
        self.webSocket = webSocket
        self.webSocket.delegate = self
    }
    
    func disconnect() {
        reconnect = false
        webSocket.disconnect()
    }
    
    func connect() {
        reconnect = true
        webSocket.connect()
    }
    
    private func autoReconnect() {
        if reconnectWait < 10 {
            reconnectWait += 1
        }
        webSocket.connect()
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("WebSocket Connected")
        reconnectWait = 0
        delegate?.webSocketDidConnect(self)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("WebSocket Disconnected", error)
        delegate?.webSocketDidDisconnect(self, error: error)

        // 再接続
        guard reconnect else { return }
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + Double(reconnectWait)) { [weak self] in
            self?.autoReconnect()
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("WebSocket Received Text")
        delegate?.webSocketDidReceiveMessage(self, text: text)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("WebSocket Received Data 🤔", data)
    }
}

protocol WebSocketWrapperDelegate: class {
    func webSocketDidConnect(_ wrapper: WebSocketWrapper)
    func webSocketDidDisconnect(_ wrapper: WebSocketWrapper, error: Error?)
    func webSocketDidReceiveMessage(_ wrapper: WebSocketWrapper, text: String)
}

extension MastodonUserToken {
    func getWebSocket(endpoint: String) -> Promise<WebSocketWrapper> {
        return self.app.instance.getInfo().then { info in
            var streamingUrlString = ""
            streamingUrlString += info["urls"]["streaming_api"].string ?? "wss://"+self.app.instance.hostName
            streamingUrlString += "/api/v1/streaming/?stream=" + endpoint
            let protocols: [String]?
            if MastodonVersionStringToInt(info["version"].stringValue) >= MastodonVersionStringToInt("2.8.4") {
                protocols = [self.token]
            } else {
                streamingUrlString += "&access_token=" + self.token
                protocols = nil
            }
            var urlRequest = URLRequest(url: URL(string: streamingUrlString)!)
            urlRequest.addValue(UserAgentString, forHTTPHeaderField: "User-Agent")
            let webSocket =  WebSocket(request: urlRequest, protocols: protocols)
            let wrap = WebSocketWrapper(webSocket: webSocket)
            webSockets.append(wrap)
            return Promise(resolved: wrap)
        }
    }
}

func allWebSocketDisconnect() {
    webSockets.forEach { value in
        value.disconnect()
    }
    webSockets = []
}
