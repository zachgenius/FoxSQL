//
// Created by Zach Wang on 2019-03-02.
// Copyright (c) 2019 WildFox. All rights reserved.
//

#import "MySQLBridge.h"
#import <mysql.h>

@implementation MySQLBridge {

}
+ (BOOL)isPrivateKey:(unsigned int)flag {
    BOOL isPriv = IS_PRI_KEY(flag);
    return isPriv;
}

@end
