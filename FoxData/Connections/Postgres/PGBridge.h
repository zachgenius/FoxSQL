//
//  PGBridge.h Postgres桥接, 都是同步方法, 外部进行异步调用
//  FoxData
//
//  Created by Zach Wang on 3/29/19.
//  Copyright © 2019 WildFox. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN


@class DBConnectionModel;
@class DBQueryResultItemModel;
@interface PGBridge : NSObject
- (void)checkAuth:(DBConnectionModel *)model
             host:(NSString*)host
             port:(int)port
         callback:(void(^)(int errorCode, NSString* message))callback;

- (void)connect:(DBConnectionModel *)model
           host:(NSString*)host
           port:(int)port
       callback:(void(^)(int errorCode, NSString* message))callback;

- (void)close;

- (void)getDatabase:(void(^)(NSArray<NSString*>* _Nullable results, NSString* info))callback;
- (void)getTables:(NSString*)dbName
         callback:(void(^)(NSDictionary<NSString*, NSArray<NSString*>*>* _Nullable results, NSString* info))callback;
- (void)getViews:(NSString*)dbName
        callback:(void(^)( NSDictionary<NSString*, NSArray<NSString*>*>* _Nullable  results, NSString* info))callback;
- (void)getProcedures:(NSString*)dbName
             callback:(void(^)(NSDictionary<NSString*, NSArray<NSString*>*>* _Nullable results, NSString* info))callback;
- (void)getFunctions:(NSString*)dbName
            callback:(void(^)(NSDictionary<NSString*, NSArray<NSString*>*>* _Nullable results, NSString* info))callback;

- (void)getCreateValue:(int)type
              database:(NSString*)db
                  name:(NSString*)name
              callback:(void(^)(NSString* result, int type, NSString* name, NSString* db, NSString* info))callback;

- (void)cacheKeywords:(NSString*)dbName;
- (void)query:(NSString*)sql
     database:(NSString*)db
     callback:(void(^)(NSArray<NSArray<DBQueryResultItemModel*>*>* _Nullable result, NSString* sql, NSString* db, NSString* info, int statusCode))callback;

@end



NS_ASSUME_NONNULL_END
