//
//  DBBaseModel.m
//  0407_FMDB
//
//  Created by cs on 2018/4/7.
//  Copyright © 2018年 cs. All rights reserved.
//

#import "DBBaseModel.h"
#import "DBHelper.h"

#define dbTimeCount @"recent_time"

@implementation DBBaseModel

#pragma mark - override method
+ (void)initialize {
    if (self != [DBBaseModel self]) {
        [self createTable];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSDictionary *dic = [self.class getAllProperties];
        _columeNames = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];
        _columeTypes = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];
    }
    return self;
}

#pragma mark - base method
// 获取该类的所有属性
+ (NSDictionary *)getPropertys {
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    NSArray *theTrasients = [[self class] transients];
    unsigned int outCount,i;
    
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        // 获取属性名
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        if ([theTrasients containsObject:propertyName]) {
            continue;
        }
        [proNames addObject:propertyName];
        // 获取属性类型参数
        NSString *propertyType = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        if ([propertyType hasPrefix:@"T@"]) {
            [proTypes addObject:SQL_TEXT];
        } else if ([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"]) {
            [proTypes addObject:SQL_INTEGER];
        } else {
            [proTypes addObject:SQL_REAL];
        }
    }
    free(properties);
    
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",nil];
}

// 获取所有属性，包含主键pk
+ (NSDictionary *)getAllProperties {
    NSDictionary *dict = [self.class getPropertys];
    
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    
    [proNames addObject:PrimaryId];
    [proTypes addObject:[NSString stringWithFormat:@"%@ %@",SQL_INTEGER,PrimaryKey]];
    [proNames addObjectsFromArray:[dict objectForKey:@"name"]];
    [proTypes addObjectsFromArray:[dict objectForKey:@"type"]];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type", nil];
}

// 数据库中是否存在表
+ (bool)isExistInTable {
    __block bool result = NO;
    DBHelper *dbHelper = [DBHelper sharedHelper];
    [dbHelper.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *tableName = NSStringFromClass(self.class);
        result = [db tableExists:tableName];
    }];
    return result;
}

// 表中的字段
+ (NSArray *)getColumns {
    DBHelper *dbHelper = [DBHelper sharedHelper];
    NSMutableArray *columns = [NSMutableArray array];
    [dbHelper.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *tableName = NSStringFromClass(self.class);
        FMResultSet *resultSet = [db getTableSchema:tableName];
        while ([resultSet next]) {
            NSString *column = [resultSet stringForColumn:@"name"];
            [columns addObject:column];
        }
    }];
    return [columns copy];
}

// 创建表 - 如果已经创建，返回YES
+ (BOOL)createTable {
    FMDatabase *db = [FMDatabase databaseWithPath:[DBHelper dbPath]];
    if (![db open]) {
        NSLog(@"数据库打开失败");
        return NO;
    }
    
    NSString *tableName = NSStringFromClass(self.class);
    NSString *columeAndType = [self.class getColumeAndTypeString];
    NSString *sql = [NSString stringWithFormat:@"create table if not exists %@(%@);",tableName,columeAndType];
    
    if (![db executeUpdate:sql]) {
        return NO;
    }
    
    NSMutableArray *columns = [NSMutableArray array];
    FMResultSet *resultSet = [db getTableSchema:tableName];
    while ([resultSet next]) {
        NSString *column = [resultSet stringForColumn:@"name"];
        [columns addObject:column];
    }
    
    NSDictionary *dict = [self.class getAllProperties];
    NSArray *properties = [dict objectForKey:@"name"];
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"not (self in %@)",columns];
    //过滤数组
    NSArray *resultArray = [properties filteredArrayUsingPredicate:filterPredicate];
    
    for (NSString *column in resultArray) {
        NSUInteger index = [properties indexOfObject:column];
        NSString *proType = [[dict objectForKey:@"type"] objectAtIndex:index];
        NSString *fieldSql = [NSString stringWithFormat:@"%@ %@",column,proType];
        NSString *sql = [NSString stringWithFormat:@"alter table %@ add column %@",NSStringFromClass(self.class),fieldSql];
        if (![db executeUpdate:sql]) {
            return NO;
        }
    }
    
    [db close];
    return YES;
}

// 数据是否存在
- (BOOL)isExsistObj {
    id otherPaimaryValue = [self valueForKey:_keyWord];
    DBHelper *dbHelper = [DBHelper sharedHelper];
    __block bool isExist = NO;
    __block DBBaseModel *weakSelf = self;
    
    [dbHelper.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@ = '%@'",tableName,weakSelf.keyWord,otherPaimaryValue];
        FMResultSet *aResult = [db executeQuery:sql];
        if ([aResult next]) {
            isExist = YES;
        } else {
            isExist = NO;
        }
        [aResult close];
    }];
    
    return isExist;
}

// 是保存还是更新
- (bool)saveOrUpdate {
//    bool isExists = [self isExsistObj];
//    if (isExists) {
//        return [self update];
//    } else {
        return [self save];
//    }
}

#pragma mark - save
// 保存单个数据
- (bool)save {
    // 保存修改时间
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    NSString *str = [NSString stringWithFormat:@"%.0f",time];
    
    NSString *tableName = NSStringFromClass(self.class);
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray array];
    
    for (int i = 0; i < self.columeNames.count; i++) {
        NSString *proName = [self.columeNames objectAtIndex:i];
        if ([proName isEqualToString:PrimaryId]) {
            continue;
        }
        
        [keyString appendFormat:@"%@,",proName];
        [valueString appendString:@"?,"];
        id value;
        
        if ([proName isEqualToString:dbTimeCount]) {
            value = str;
        } else {
            value = [self valueForKey:proName];
        }
        
        [insertValues addObject:value];
    }
    
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
    
    DBHelper *dbHelper = [DBHelper sharedHelper];
    __block bool result = NO;
    
    [dbHelper.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"insert into %@(%@) values (%@);",tableName,keyString,valueString];
        result = [db executeUpdate:sql withArgumentsInArray:insertValues];
        self.pk = result ? [NSNumber numberWithLongLong:db.lastInsertRowId].intValue : 0;
        NSLog(result ? @"插入成功" : @"插入失败");
    }];
    
    return result;
}

// 批量保存用户对象
+ (bool)saveObjects:(NSArray *)array {
    // 判断是否是 DBBaseModel 的子类
    for (DBBaseModel *model in array) {
        if (![model isKindOfClass:[DBBaseModel class]]) {
            return NO;
        }
    }
    
    __block bool result = YES;
    DBHelper *dbHelper = [DBHelper sharedHelper];
    
    // 如有要支持业务
    [dbHelper.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (DBBaseModel *model in array) {
            // 保存修改时间
            NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
            NSString *str = [NSString stringWithFormat:@"%.0f",time];
            
            NSString *tableName = NSStringFromClass(model.class);
            NSMutableString *keyString = [NSMutableString string];
            NSMutableString *valueString = [NSMutableString string];
            NSMutableArray *insertValues = [NSMutableArray array];
            
            for (int i = 0; i < model.columeNames.count; i++) {
                NSString *proName = [model.columeNames objectAtIndex:i];
                if ([proName isEqualToString:PrimaryId]) {
                    continue;
                }
                
                [keyString appendFormat:@"%@,",proName];
                [valueString appendString:@"?,"];
                id value;
                
                if ([proName isEqualToString:dbTimeCount]) {
                    value = str;
                } else {
                    value = [self valueForKey:proName];
                }
                if (!value) {
                    value = @"";
                }
                
                [insertValues addObject:value];
            }
            
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
            
            NSString *sql = [NSString stringWithFormat:@"insert into %@(%@) values (%@);",tableName,keyString,valueString];
            bool flag = [db executeUpdate:sql withArgumentsInArray:insertValues];
            model.pk = flag ? [NSNumber numberWithLongLong:db.lastInsertRowId].intValue : 0;
            
            if (!flag) {
                result = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return result;
}

#pragma mark - update

// 更新单个对象
- (BOOL)update {
    //设置更新时间
    NSTimeInterval time = [[NSDate date]timeIntervalSince1970];
    NSString *str = [NSString stringWithFormat:@"%.0f",time];
    
    DBHelper *dbHelper = [DBHelper sharedHelper];
    __block BOOL result = NO;
    
    [dbHelper.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValues = [self valueForKey:self.keyWord];
        
        NSMutableString *keyString = [NSMutableString string];
        NSMutableArray *updateValues = [NSMutableArray array];
        
        for (int i = 0; i < self.columeNames.count; i++) {
            NSString *proName = [self.columeNames objectAtIndex:i];
            if ([proName isEqualToString:self.keyWord]) {
                continue;
            }
            if ([proName isEqualToString:PrimaryId]) {
                continue;
            }
            
            [keyString appendFormat:@" %@=?@,",proName];
            id value;
            
            if ([proName isEqualToString:dbTimeCount]) {
                value = str;
            } else {
                value = [self valueForKey:proName];
            }
            if (!value) {
                value = @"";
            }
            
            [updateValues addObject:value];
        }
        
        // 删除最后那个逗号
        [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
        NSString *sql = [NSString stringWithFormat:@"update %@ set %@ where %@ = ?;",tableName,keyString,self.keyWord];
        [updateValues addObject:primaryValues];
        result = [db executeUpdate:sql withArgumentsInArray:updateValues];
        NSLog(result ? @"更新成功" : @"更新失败");
    }];
    return result;
}

// 批量更新用户对象
+ (BOOL)updateObjects:(NSArray *)array {
    for (DBBaseModel *model in array) {
        if (![model isKindOfClass:[DBBaseModel class]]) {
            return NO;
        }
    }
    __block BOOL result = YES;
    DBHelper *dbHelper = [DBHelper sharedHelper];
    
    // 如果要支持事务
    [dbHelper.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (DBBaseModel *model in array) {
            //设置更新时间
            NSTimeInterval time = [[NSDate date]timeIntervalSince1970];
            NSString *str = [NSString stringWithFormat:@"%.0f",time];
            
            NSString *tableName = NSStringFromClass(model.class);
            id primaryValue = [model valueForKey:PrimaryId];
            if (!primaryValue || primaryValue <= 0) {
                result = NO;
                *rollback = YES;
                return;
            }
            
            NSMutableString *keyString = [NSMutableString string];
            NSMutableArray *updateValues = [NSMutableArray array];
            
            for (int i = 0; i < model.columeNames.count; i++) {
                NSString *proName = [model.columeNames objectAtIndex:i];
                if ([proName isEqualToString:model.keyWord]) {
                    continue;
                }
                if ([proName isEqualToString:PrimaryId]) {
                    continue;
                }
                
                [keyString appendFormat:@" %@=?@,",proName];
                id value;
                
                if ([proName isEqualToString:dbTimeCount]) {
                    value = str;
                } else {
                    value = [self valueForKey:proName];
                }
                if (!value) {
                    value = @"";
                }
                
                [updateValues addObject:value];
            }
            
            // 删除最后那个逗号
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            NSString *sql = [NSString stringWithFormat:@"update %@ set %@ where %@ = ?;",tableName,keyString,PrimaryId];
            [updateValues addObject:primaryValue];
            bool flag = [db executeUpdate:sql withArgumentsInArray:updateValues];
            NSLog(flag ? @"更新成功" : @"更新失败");

            if (!flag) {
                result = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    
    return result;
}

#pragma mark - delete

// 删除单个对象
- (BOOL)deleteObject {
    DBHelper *dbHelper = [DBHelper sharedHelper];
    __block bool result = NO;
    [dbHelper.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValue = [self valueForKey:PrimaryId];
        
        if (!primaryValue || primaryValue <= 0) {
            return;
        }
        
        NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@ = ?",tableName,PrimaryId];
        result = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
        NSLog(result ? @"删除成功" : @"删除失败");
    }];
    return result;
}

// 批量删除用户对象
+ (BOOL)deleteObjects:(NSArray *)array {
    for (DBBaseModel *model in array) {
        if (![model isKindOfClass:[DBBaseModel class]]) {
            return NO;
        }
    }
    
    __block bool result = YES;
    DBHelper *dbHelper = [DBHelper sharedHelper];
    // 如果要支持事务
    [dbHelper.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (DBBaseModel *model in array) {
            NSString *tableName = NSStringFromClass(model.class);
            id primaryValue = [model valueForKey:PrimaryId];
            
            if (!primaryValue || primaryValue <= 0) {
                return;
            }
            
            NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@ = ?",tableName,PrimaryId];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
            NSLog(flag?@"删除成功":@"删除失败");
            if (!flag) {
                result = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return result;
}

// 通过条件删除数据
+ (BOOL)deleteObjectsByCriteria:(NSString *)criteria {
    DBHelper *dbHelper = [DBHelper sharedHelper];
    __block bool res = NO;
    [dbHelper.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"delete from %@ %@ ",tableName,criteria];
        res = [db executeUpdate:sql];
        NSLog(res?@"删除成功":@"删除失败");
    }];
    return res;
}

// 清空表
+ (BOOL)clearTable {
    DBHelper *dbHelper = [DBHelper sharedHelper];
    __block bool res = NO;
    [dbHelper.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"delete from %@",tableName];
        res = [db executeUpdate:sql];
        NSLog(res ? @"清空成功" : @"清空失败");
    }];
    return res;
}

#pragma mark - query

// 查询全部数据
+ (NSArray *)findAll {
    DBHelper *dbHelper = [DBHelper sharedHelper];
    NSMutableArray *users = [NSMutableArray array];
    
    [dbHelper.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"select * from %@",tableName];
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            DBBaseModel *model = [[self.class alloc] init];
            for (int i = 0; i < model.columeNames.count; i++) {
                NSString *columeName = [model.columeNames objectAtIndex:i];
                NSString *columeType = [model.columeTypes objectAtIndex:i];
                if ([columeType isEqualToString:SQL_TEXT]) {
                    [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                } else {
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                }
            }
            [users addObject:model];
            FMDBRelease(model);
        }
    }];
    return users;
}

// 查找某条数据
+ (instancetype)findFirstByCriteria:(NSString *)criteria {
    NSArray *results = [self.class findByCriteria:criteria];
    
    if (results.count < 1) {
        return nil;
    }
    
    return [results firstObject];
}

// 通过 key 查询
+ (instancetype)findByPK:(int)inPk {
    NSString *condition = [NSString stringWithFormat:@"where %@=%d",PrimaryId,inPk];
    return [self findFirstByCriteria:condition];
}

// 通过条件查找数据
+ (NSArray *)findByCriteria:(NSString *)criteria {
    DBHelper *dbHelper = [DBHelper sharedHelper];
    NSMutableArray *users = [NSMutableArray array];
    
    [dbHelper.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"select * from %@ %@",tableName,criteria];
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            DBBaseModel *model = [[self.class alloc] init];
            for (int i=0; i< model.columeNames.count; i++) {
                NSString *columeName = [model.columeNames objectAtIndex:i];
                NSString *columeType = [model.columeTypes objectAtIndex:i];
                if ([columeType isEqualToString:SQL_TEXT]) {
                    [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                } else {
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                }
            }
            [users addObject:model];
            FMDBRelease(model);
        }
    }];
    
    return users;
}

// 值 为 通过 条件查找  － 返回数组中的第一个
+ (instancetype)findWhereColoum:(NSString *)coloum equleToValue:(NSString *)value {
    return [[self class] findFirstByCriteria:[NSString stringWithFormat:@"where %@='%@'",coloum,value]];
}

#pragma mark - util method

+ (NSString *)getColumeAndTypeString {
    NSMutableString *pars = [NSMutableString string];
    NSDictionary *dict = [self.class getAllProperties];
    
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    NSMutableArray *proTypes = [dict objectForKey:@"type"];
    
    for (int i = 0; i < proNames.count; i++) {
        [pars appendFormat:@"%@ %@",[proNames objectAtIndex:i],[proTypes objectAtIndex:i]];
        if (i + 1 != proNames.count) {
            [pars appendString:@","];
        }
    }
    
    return pars;
}

- (NSString *)description {
    NSString *result = @"";
    NSDictionary *dict = [self.class getAllProperties];
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    for (int i = 0; i < proNames.count; i++) {
        NSString *proName = [proNames objectAtIndex:i];
        id proValue = [self valueForKey:proName];
        result = [result stringByAppendingFormat:@"%@:%@\n",proName,proValue];
    }
    return result;
}

#pragma mark - must be override method
/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
 */
+ (NSArray *)transients
{
    return @[];
}
@end
