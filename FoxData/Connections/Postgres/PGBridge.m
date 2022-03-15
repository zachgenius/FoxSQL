//
//  PGBridge.m
//  FoxData
//
//  Created by Zach Wang on 3/29/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

#import "PGBridge.h"
#import "SSHTunnel.h"
#import "FoxData-Swift.h"
//#import <libpq/libpq-fe.h>

@interface PGBridge ()
//@property PGconn* conn;
@end

@implementation PGBridge

- (void)checkAuth:(DBConnectionModel *)server
             host:(NSString*)host
             port:(int)port
         callback:(void (^)(int errorCode, NSString *message))callback {
//    PGconn     *conn;
//
//    /* Make a connection to the database */
//    conn = PQsetdbLogin(
//                        [host UTF8String],
//                        [[NSString stringWithFormat:@"%d",port] UTF8String],
//                        NULL, NULL,
//                        [server.db UTF8String],
//                        [server.username UTF8String],
//                        [server.password UTF8String]);
//
//    /* Check to see that the backend connection was successfully made */
//    int status = PQstatus(self.conn);
//    if (status != CONNECTION_OK)
//    {
//        const char* msg = PQerrorMessage(conn);
//        fprintf(stderr, "Connection to database failed: %s", msg);
//
//        NSString* msgStr = [NSString stringWithUTF8String:msg];
//        callback(-1, [NSString stringWithFormat:@"Postgres Authentication Failed: %@", msgStr]);
//        [self exitNicely:conn];
//
//    }else {
//        callback(0, @"Success");
//    }
}

-(void)close{
//    if (self.conn) {
//        [self exitNicely:self.conn];
//    }
}

//-(void)exitNicely:(PGconn *)conn
//{
////    if (conn == nil) {
////        return;
////    }
////    PQfinish(conn);
//    
//}

- (void)connect:(DBConnectionModel *)server host:(NSString *)host port:(int)port callback:(void (^)(int, NSString * _Nonnull))callback{
    
//    /* Make a connection to the database */
//    self.conn = PQsetdbLogin(
//                        [host UTF8String],
//                        [[NSString stringWithFormat:@"%d",port] UTF8String],
//                        NULL, NULL,
//                        [server.db UTF8String],
//                        [server.username UTF8String],
//                        [server.password UTF8String]);
//
//    /* Check to see that the backend connection was successfully made */
//    int status = PQstatus(self.conn);
//    if (status != CONNECTION_OK)
//    {
//        const char* msg = PQerrorMessage(self.conn);
//        fprintf(stderr, "Connection to database failed: %s", msg);
//
//        NSString* msgStr = [NSString stringWithUTF8String:msg];
//        callback(-1, [NSString stringWithFormat:@"Postgres Authentication Failed: %@", msgStr]);
//        [self exitNicely:self.conn];
//        self.conn = nil;
//
//    }else {
//        callback(0, @"Success");
//    }
}

- (void)getDatabase:(void (^)(NSArray<NSString *> *, NSString * _Nonnull))callback{
//    if (!self.conn) {
//        [self exitNicely:self.conn];
//        self.conn = nil;
//        callback(nil, @"Lost Connection. Please try again later");
//        return;
//    }
}

@end
