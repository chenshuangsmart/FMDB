//
//  DBHelper.h
//  0407_FMDB
//
//  Created by cs on 2018/4/7.
//  Copyright © 2018年 cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

/** 数据库管理工具 */
@interface DBHelper : NSObject

/** 数据库操作队列 */
@property(nonatomic, strong, readonly)FMDatabaseQueue *dbQueue;

/** 获取数据库管理类单例 */
+ (DBHelper *)sharedHelper;

/** 数据库文件沙盒地址 */
+ (NSString *)dbPath;

@end
