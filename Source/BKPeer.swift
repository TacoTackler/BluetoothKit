//
//  BluetoothKit
//
//  Copyright (c) 2015 Rasmus Taulborg Hummelmose - https://github.com/rasmusth
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public typealias BKSendDataCompletionHandler = ((data: NSData, remotePeer: BKRemotePeer, error: BKError?) -> Void)

public class BKPeer {
    
    /// The configuration the BKCentral object was started with.
    public var configuration: BKConfiguration? {
        return nil
    }
    
    internal var connectedRemotePeers: [BKRemotePeer] {
        return _connectedRemotePeers
    }
    internal var _connectedRemotePeers: [BKRemotePeer] = []
    internal var sendDataTasks: [BKSendDataTask] = []
    
    /**
     Sends data to a connected remote central.
     - parameter data: The data to send.
     - parameter remotePeer: The destination of the data payload.
     - parameter completionHandler: A completion handler allowing you to react in case the data failed to send or once it was sent succesfully.
     */
    public func sendData(data: NSData, toRemotePeer remotePeer: BKRemotePeer, completionHandler: BKSendDataCompletionHandler?) {
        guard connectedRemotePeers.contains(remotePeer) else {
            completionHandler?(data: data, remotePeer: remotePeer, error: BKError.RemotePeerNotConnected)
            return
        }
        let sendDataTask = BKSendDataTask(data: data, destination: remotePeer, completionHandler: completionHandler)
        sendDataTasks.append(sendDataTask)
        if sendDataTasks.count == 1 {
            processSendDataTasks()
        }
    }
    
    internal func processSendDataTasks() {
        guard sendDataTasks.count > 0 else {
            return
        }
        let nextTask = sendDataTasks.first!
        if nextTask.sentAllData {
            let sentEndOfDataMark = sendData(configuration!.endOfDataMark, toRemotePeer: nextTask.destination)
            if (sentEndOfDataMark) {
                sendDataTasks.removeAtIndex(sendDataTasks.indexOf(nextTask)!)
                nextTask.completionHandler?(data: nextTask.data, remotePeer: nextTask.destination, error: nil)
                processSendDataTasks()
            } else {
                return
            }
        }
        let nextPayload = nextTask.nextPayload
        let sentNextPayload = sendData(nextPayload, toRemotePeer: nextTask.destination)
        if sentNextPayload {
            nextTask.offset += nextPayload.length
            processSendDataTasks()
        } else {
            return
        }
    }
    
    internal func failSendDataTasksForRemotePeer(remotePeer: BKRemotePeer) {
        for sendDataTask in sendDataTasks.filter({ $0.destination == remotePeer }) {
            sendDataTasks.removeAtIndex(sendDataTasks.indexOf(sendDataTask)!)
            sendDataTask.completionHandler?(data: sendDataTask.data, remotePeer: sendDataTask.destination, error: .RemotePeerNotConnected)
        }
    }
    
    internal func sendData(data: NSData, toRemotePeer remotePeer: BKRemotePeer) -> Bool {
        fatalError("Function must be overridden by subclass")
    }
    
}
