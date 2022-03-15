//
//  SSHTunnel.h
//  FoxData
//
//  Created by Zach Wang on 3/16/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SSHTunnelConnectedCallback)(NSString* localhost, int port);
typedef void (^SSHTunnelFailedCallback)(int errorCode, NSString* message);

@protocol SSHTunnelDelegate;

@interface SSHTunnel : NSObject

@property BOOL isStop;

@property (weak, nonatomic) id<SSHTunnelDelegate> delegate;
@property NSString* sshHost;
@property NSString* sshUsername;
@property NSString* sshPassword;
@property int sshPort;
@property BOOL sshIsKey;
@property NSString* sshPubKey;
@property NSString* sshPrivKey;
@property NSString* sshPrivKeyPassword;

///想要在远程服务器连接的服务器地址
@property NSString* remoteDestHost;
@property int remoteDestPort;

@property NSString* localListeningHost;
@property int localListeningPort;

@property BOOL isConnected;

- (void) connect;

- (void) connectWithSuccess:(SSHTunnelConnectedCallback)success
                withFailure:(SSHTunnelFailedCallback)failure;

/**
 * ipv6
 */
//- (void) connect6;

- (void) close;
@end

NS_ASSUME_NONNULL_END
