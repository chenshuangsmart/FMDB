//
//  DBBaseModel.h
//  0407_FMDB
//
//  Created by cs on 2018/4/7.
//  Copyright © 2018年 cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/** SQLite 5种数据类型 */
#define SQL_TEXT    @"TEXT"
#define SQL_INTEGER @"INTEGER"
#define SQL_REAL    @"REAL"
#define SQL_BLOB    @"BLOB"
#define SQL_NULL    @"NULL"
#define PrimaryKey  @"Primary key"
#define PrimaryId   @"pk"

/** 数据库对象的父类 */
@interface DBBaseModel : NSObject
/** 主健 id */
@property(nonatomic, assign)int pk;
/** key word */
@property(nonatomic, strong)NSString *keyWord;
/** 列名 */
@property(nonatomic, strong, readonly)NSMutableArray *columeNames;
/** 列类型 */
@property(nonatomic, strong, readonly) NSMutableArray *columeTypes;

#pragma mark - function

/** 获取该类（模型）中的所有属性 runtime  */
+ (NSDictionary *)getPropertys;

/** 获取所有属性，包括主键 */
+ (NSDictionary *)getAllProperties;

/** 数据库中是否存在表 */
+ (bool)isExistInTable;

/** 表中的字段 */
+ (NSArray *)getColumns;

/** 保存或更新 如果不存在主键，保存.有主键，则更新*/
- (bool)saveOrUpdate;

/** 保存单个数据 */
- (bool)save;

/** 批量保存数据 */
+ (bool)saveObjects:(NSArray *)array;

/** 更新单个数据 */
- (BOOL)update;

/** 批量更新数据*/
+ (BOOL)updateObjects:(NSArray *)array;

/** 删除单个数据 */
- (BOOL)deleteObject;

/** 批量删除数据 */
+ (BOOL)deleteObjects:(NSArray *)array;

/** 通过条件删除数据 */
+ (BOOL)deleteObjectsByCriteria:(NSString *)criteria;

/** 清空表 */
+ (BOOL)clearTable;

/** 查询全部数据 */
+ (NSArray *)findAll;

/** 通过主键查询 */
+ (instancetype)findByPK:(int)inPk;

/** 查找某条数据 */
+ (instancetype)findFirstByCriteria:(NSString *)criteria;

/** 值 为 通过 条件查找  － 返回数组中的第一个 */
+ (instancetype)findWhereColoum:(NSString *)coloum equleToValue:(NSString *)value;

/** 通过条件查找数据
 * 这样可以进行分页查询 @" WHERE pk > 5 limit 10"
 */
+ (NSArray *)findByCriteria:(NSString *)criteria;

#pragma mark - must be override method

/**
 * 创建表
 * 如果已经创建，返回YES
 */
+ (BOOL)createTable;

/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
 */
+ (NSArray *)transients;

/** 数据是否存在 */
- (BOOL )isExsistObj;

@end
