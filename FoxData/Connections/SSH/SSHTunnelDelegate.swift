//
// Created by Zach Wang on 2019-03-17.
// Copyright (c) 2019 WildFox. All rights reserved.
//

import Foundation

@objc protocol SSHTunnelDelegate : class {
    func sshTunnelSuccess(_ localHost:String, withPort port:Int32)
    func sshTunnelFailure(_ code:Int32, withInfo info:String)
    func sshTunnelRemoteClosed()
}
