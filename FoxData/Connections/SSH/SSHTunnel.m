//
//  SSHTunnel.m
//  FoxData
//
//  Created by Zach Wang on 3/16/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

#import "SSHTunnel.h"
#import "libssh2.h"
#import "FoxData-Swift.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/time.h>
#import <GSS/gssapi_protos.h>

@interface SSHTunnel(){
    dispatch_queue_t queue;

}
@end

@implementation SSHTunnel

- (SSHTunnel *)init {
    if (self = [super init]){
        queue = dispatch_queue_create("SSHTunnelQueue", NULL);
        _isStop = NO;
        _sshHost = @"";
        _sshUsername = @"";
        _sshPassword = @"";
        _sshIsKey = NO;
        _sshPort = 22;
        _localListeningHost = @"127.0.0.1";
        _localListeningPort = 10100;
        _isConnected = NO;
        _sshPubKey = @"";
        _sshPrivKey = @"";
        _sshPrivKeyPassword = @"";
    };
    return self;
}

- (void)connect {
    __weak SSHTunnel* weakSelf = self;
    [self connectWithSuccess:^(NSString * _Nonnull localhost, int port) {
        if (weakSelf.delegate) {
            [weakSelf.delegate sshTunnelSuccess:localhost withPort:port];
        }
    } withFailure:^(int errorCode, NSString * _Nonnull message) {
        if (weakSelf.delegate) {
            if (errorCode > 0) {
                [weakSelf.delegate sshTunnelRemoteClosed];
            }
            else{
                [weakSelf.delegate sshTunnelFailure:errorCode withInfo:message];
            }
        }
    }];
}

- (void)connectWithSuccess:(SSHTunnelConnectedCallback)success
               withFailure:(SSHTunnelFailedCallback)failure {
    if (_isConnected){
        if (success) {
            success(self.localListeningHost, self.localListeningPort);
        }
        return;
    }

    __weak SSHTunnel * weakSelf = self;
    dispatch_async(queue, ^{
        weakSelf.isStop = NO;
        int rc, i;
        struct sockaddr_in sin;
        socklen_t sinlen;
        const char *fingerprint;
        char *userauthlist;
        LIBSSH2_SESSION *session;
        LIBSSH2_CHANNEL *channel = NULL;
        const char *shost;
        unsigned int sport;
        fd_set fds;
        struct timeval tv;
        ssize_t len, wr;
        char buf[16384];
        
        int sockopt, sock = -1;
        int listensock = -1, forwardsock = -1;
        rc = libssh2_init (0);
        
        if (rc != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure){
                    failure(-1, [NSString stringWithFormat:@"libssh2 initialization failed (%d)\n", rc]);
                }

            });
            fprintf (stderr, "libssh2 initialization failed (%d)\n", rc);
            return;
        }
        
        /* Connect to SSH server */
        sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
        
        if (sock == -1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure){
                    failure(-2, @"socket error");
                }
            });
            perror("socket");
            return;
        }
        
        sin.sin_family = AF_INET;
        if (INADDR_NONE == (sin.sin_addr.s_addr = inet_addr([weakSelf.sshHost UTF8String]))) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure){
                    failure(-3, @"invalid host address");
                }
            });
            perror("inet_addr");
            return ;
        }
        sin.sin_port = htons(weakSelf.sshPort);
        if (connect(sock, (struct sockaddr*)(&sin),
                    sizeof(struct sockaddr_in)) != 0) {
            fprintf(stderr, "failed to connect!\n");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure){
                    failure(-4, @"failed to connect!");
                }
            });
            return ;
        }
        
        /* Create a session instance */
        session = libssh2_session_init();
        
        if(!session) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure){
                    failure(-5, @"Could not initialize SSH session!");
                }
            });
            fprintf(stderr, "Could not initialize SSH session!\n");
            return ;
        }
        
        /* ... start it up. This will trade welcome banners, exchange keys,
         * and setup crypto, compression, and MAC layers
         */
        rc = libssh2_session_handshake(session, sock);
        
        if(rc) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure){
                    failure(-6, [NSString stringWithFormat:@"Error when starting up SSH session: (%d)\n", rc]);
                }
                [weakSelf.delegate sshTunnelFailure:-5 withInfo:[NSString stringWithFormat:@"Error when starting up SSH session: (%d)\n", rc]];
            });
            fprintf(stderr, "Error when starting up SSH session: %d\n", rc);
            return ;
        }
        
        /* At this point we havn't yet authenticated.  The first thing to do
         * is check the hostkey's fingerprint against our known hosts Your app
         * may have it hard coded, may go to a file, may present it to the
         * user, that's your call
         */
        fingerprint = libssh2_hostkey_hash(session, LIBSSH2_HOSTKEY_HASH_SHA1);
        
        fprintf(stderr, "Fingerprint: ");
        for(i = 0; i < 20; i++)
            fprintf(stderr, "%02X ", (unsigned char)fingerprint[i]);
        fprintf(stderr, "\n");
        
        /* check what authentication methods are available */
        userauthlist = libssh2_userauth_list(session, [weakSelf.sshUsername UTF8String], weakSelf.sshUsername.length);
        
        fprintf(stderr, "Authentication methods: %s\n", userauthlist);
        if (weakSelf && weakSelf.sshIsKey) {
            NSString* privKey = [NSString stringWithFormat:@"-----BEGIN RSA PRIVATE KEY-----\n%@\n-----END RSA PRIVATE KEY-----", self.sshPrivKey];
            if (libssh2_userauth_publickey_frommemory(session,
                                                      [weakSelf.sshUsername UTF8String],
                                                      weakSelf.sshUsername.length,
                                                      [weakSelf.sshPubKey UTF8String],
                                                      weakSelf.sshPubKey.length,
                                                      [privKey UTF8String],
                                                      weakSelf.sshPrivKey.length,
                                                      [weakSelf.sshPassword UTF8String]) != 0){
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure){
                        failure(-7, @"Authentication with authkey failed.");
                    }
                });
                fprintf(stderr, "Authentication by authkey failed.\n");
                goto shutdown;
            }
            
        } else{
            
            if (libssh2_userauth_password(session, [weakSelf.sshUsername UTF8String], [weakSelf.sshPassword UTF8String]) != 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure){
                        failure(-7, @"Authentication by password failed");
                    }
                });
                fprintf(stderr, "Authentication with password failed.\n");
                goto shutdown;
            }
        }
        
        
        listensock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
        if (listensock == -1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure){
                    failure(-8, @"Local socket error");
                }
                
            });
            perror("local socket");
            goto shutdown;
        }
        
        
        sin.sin_family = AF_INET;
        sin.sin_port = htons(weakSelf.localListeningPort);
        if (INADDR_NONE == (sin.sin_addr.s_addr = inet_addr([weakSelf.localListeningHost UTF8String]))) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure){
                    failure(-9, @"inet address error");
                }
            });
            perror("inet_addr");
            goto shutdown;
        }
        sockopt = 1;
        setsockopt(listensock, SOL_SOCKET, SO_REUSEADDR, &sockopt, sizeof(sockopt));
        sinlen=sizeof(sin);
        if (-1 == bind(listensock, (struct sockaddr *)&sin, sinlen)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure){
                    failure(-10, @"Binding local socket error");
                }
            });
            perror("bind");
            goto shutdown;
        }
        if (-1 == listen(listensock, 2)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure){
                    failure(-11, @"Listening local socket error");
                }
            });
            perror("listen");
            goto shutdown;
        }
        
        fprintf(stderr, "Waiting for TCP connection on %s:%d...\n",
                inet_ntoa(sin.sin_addr), ntohs(sin.sin_port));
        //成功
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.isConnected = YES;
                if (success) {
                    success(weakSelf.localListeningHost, weakSelf.localListeningPort);
                }
               
            });
        }
        forwardsock = accept(listensock, (struct sockaddr *)&sin, &sinlen);
        
        if (forwardsock == -1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure){
                    failure(-12, @"Forwarding acception error");
                }
            });
            perror("accept");
            goto shutdown;
        }
        
        shost = inet_ntoa(sin.sin_addr);
        sport = ntohs(sin.sin_port);
        
        fprintf(stderr, "Forwarding connection from %s:%d here to remote %s:%d\n",
                shost, sport, [weakSelf.remoteDestHost UTF8String], weakSelf.remoteDestPort);
        
        // connect to the destination through ssh
        channel = libssh2_channel_direct_tcpip_ex(session, [weakSelf.remoteDestHost UTF8String],
                                                  
                                                  weakSelf.remoteDestPort, shost, sport);
        if (!channel) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure){
                    failure(-13, @"Could not open the direct-tcpip channel!\n"
                            "(Note that this can be a problem at the server!\n"
                            "Please review the server logs.)\n");
                }
                
            });
            fprintf(stderr, "Could not open the direct-tcpip channel!\n"
                    "(Note that this can be a problem at the server!"
                    " Please review the server logs.)\n");
            goto shutdown;
        }
        
        /* Must use non-blocking IO hereafter due to the current libssh2 API */
        libssh2_session_set_blocking(session, 0);
        
        while (!weakSelf.isStop) {
            FD_ZERO(&fds);
            FD_SET(forwardsock, &fds);
            tv.tv_sec = 0;
            tv.tv_usec = 100000;
            rc = select(forwardsock + 1, &fds, NULL, NULL, &tv);
            if (-1 == rc) {
                perror("select");
                goto shutdown;
            }
            if (rc && FD_ISSET(forwardsock, &fds)) {
                len = recv(forwardsock, buf, sizeof(buf), 0);
                if (len < 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (failure){
                            failure(1, @"Connection lost");
                        }
                    });
                    perror("read");
                    goto shutdown;
                } else if (0 == len) {
                    fprintf(stderr, "The client at %s:%d disconnected!\n", shost,
                            sport);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (failure){
                            failure(1, @"Connection lost");
                        }
                    });
                    goto shutdown;
                }
                wr = 0;
                while(wr < len) {
                    i = libssh2_channel_write(channel, buf + wr, len - wr);
                    
                    if (LIBSSH2_ERROR_EAGAIN == i) {
                        continue;
                    }
                    if (i < 0) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (failure){
                                failure(1, @"Connection lost");
                            }
                        });
                        fprintf(stderr, "libssh2_channel_write: %d\n", i);
                        goto shutdown;
                    }
                    wr += i;
                }
            }
            while (!weakSelf.isStop) {
                len = libssh2_channel_read(channel, buf, sizeof(buf));
                
                if (LIBSSH2_ERROR_EAGAIN == len)
                    break;
                else if (len < 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (failure){
                            failure(1, @"Connection lost");
                        }
                    });
                    //连接突然断了
                    fprintf(stderr, "libssh2_channel_read: %d", (int)len);
                    goto shutdown;
                }
                wr = 0;
                while (wr < len) {
                    i = send(forwardsock, buf + wr, len - wr, 0);
                    if (i <= 0) {
                        //连接突然断了
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (failure){
                                failure(1, @"Connection lost");
                            }
                        });
                        perror("write");
                        goto shutdown;
                    }
                    wr += i;
                }
                if (libssh2_channel_eof(channel)) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (failure){
                            failure(2, @"Remote server closed");
                        }
                    });
                    fprintf(stderr, "The server at %s:%d disconnected!\n",
                            [weakSelf.remoteDestHost UTF8String], weakSelf.remoteDestPort);
                    goto shutdown;
                }
            }
        }
        
    shutdown:
        weakSelf.isConnected = false;
        close(forwardsock);
        close(listensock);
        if (channel)
            libssh2_channel_free(channel);
        
        libssh2_session_disconnect(session, "Client disconnecting normally");
        libssh2_session_free(session);
        close(sock);
        libssh2_exit();
        weakSelf.isConnected = NO;
        
    });
}

- (void)connect6 {

}

- (void)close {
    self.isStop = YES;
}

@end
