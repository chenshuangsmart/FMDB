//
//  DBHelper.m
//  0407_FMDB
//
//  Created by cs on 2018/4/7.
//  Copyright © 2018年 cs. All rights reserved.
//

#import "DBHelper.h"

@interface DBHelper ()
/** 数据库操作队列 */
@property(nonatomic, strong)FMDatabaseQueue *dbQueue;

@end

@implementation DBHelper

+ (DBHelper *)sharedHelper {
    static DBHelper *instance = nil;
    static dispatch_once_t onceToken;
    if (!instance) {
        dispatch_once(&onceToken, ^{
            instance = [[super allocWithZone:nil] init];
        });
    }
    return instance;
}

// lazy load
- (FMDatabaseQueue *)dbQueue {
    if (!_dbQueue) {
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[[self class] dbPath]];
    }
    return _dbQueue;
}

// 数据库地址
+ (NSString *)dbPath {
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    docsDir = [docsDir stringByAppendingPathComponent:@"AppDataBase"];
    
    bool isDir;
    bool exit = [fileManager fileExistsAtPath:docsDir isDirectory:&isDir];
    
    if (!exit || !isDir) {
        [fileManager createDirectoryAtPath:docsDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *dbPath = [docsDir stringByAppendingPathComponent:@"TierTime.sqlite"];
    return dbPath;
}

#pragma mark - 保证单例不会被创建成新对象

+ (instancetype)alloc {
    return nil;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [DBHelper sharedHelper];
}

- (id)copyWithZone:(struct _NSZone *)zone
{
    return [DBHelper sharedHelper];
}

@end
