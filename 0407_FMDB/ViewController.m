//
//  ViewController.m
//  0407_FMDB
//
//  Created by cs on 2018/4/7.
//  Copyright © 2018年 cs. All rights reserved.
//

#import "ViewController.h"
#import "FMDB.h"
#import "BGStudent.h"
#import "PicCacheModel.h"

@interface ViewController ()

/** data */
@property(nonatomic, strong)FMDatabase *db;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self createDataBase];
    
    [self insertData];
//    [self deleteData];
//    [self updateData];
//    [self sqlData];
//    [self dropDataBase];
//    [self createDatabaseQueue];
    
//    [self picCacheModel];
}

- (void)createDataBase {
    // 1.获得数据库文件的路径
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *fileName = [doc stringByAppendingPathComponent:@"student.sqlite"];
    
    // 2.获得数据库
    FMDatabase *db = [FMDatabase databaseWithPath:fileName];
    self.db = db;
    
    // 3.使用如下语句,如果打开失败,可能是权限不足或者资源不足,通常打开完操作操作后，需要调用 close 方法来关闭数据库。
    // 在和数据库交互 之前，数据库必须是打开的。如果资源或权限不足无法打开或创建数据库，都会导致打开失败。
    if ([db open]) {
        // 4.创建表
        bool result = [db executeUpdate:@"create table if not exists t_student(id integer PRIMARY KEY AUTOINCREMENT, name text not null, age integer not null)"];
        if (result) {
            NSLog(@"创建表格成功");
        }
    }
}

- (void)insertData {
    int age = 29;
    NSString *name = @"张小飞";
    
    //1.executeUpdate:不确定的参数用?来占位(后面参数必须是 OC 对象,;代表语句结束)
    [self.db executeUpdate:@"insert into t_student (name,age) values (?,?);",name,@(age)];
    
    //2.executeUpdateWithForamat:不确定的参数用%@,%d等来占位(参数为原始数据类型,执行语句不区分大小写)
    [self.db executeUpdateWithFormat:@"insert into t_student (name,age) values (%@,%i);",name,age];
    
    //3.参数是数组的使用方式
    [self.db executeUpdate:@"insert into t_student(name,age) values (?,?);" withArgumentsInArray:@[name,@(age)]];
}

- (void)deleteData {
    int idNum = 1;
    
    //1.不确定的参数用?来占位(后面参数必须是 OC 对象,需要将 int 包装成 OC 对象)
    [self.db executeUpdate:@"delete from t_student where id = ?;",@(idNum)];
    
    //2.不确定的参数用%@,%d 等来占位
    [self.db executeUpdateWithFormat:@"delete from t_student where name = %@;",@"chen"];
}

- (void)updateData {
    NSString *oldName = @"chenliang";
    NSString *newName = @" 张小飞";
    
    [self.db executeUpdate:@"update t_student set name = ? where name = ?",newName,oldName];
}

- (void)sqlData {
    // 查询整个表
    FMResultSet *resultSet = [self.db executeQuery:@"select * from t_student"];
    // 根据条件查询
//    FMResultSet *resultSet = [self.db executeQuery:@"select * from t_student where id<?",@(10)];
    
    // 变量结果集合
    while ([resultSet next]) {
        int idNum = [resultSet intForColumn:@"id"];
        NSString *name = [resultSet objectForColumn:@"name"];
        int age = [resultSet intForColumn:@"age"];
        NSLog(@"id = %d, name = %@, age = %d",idNum,name,age);
    }
}

- (void)dropDataBase {
    // 如果存在,则销毁
    [self.db executeUpdate:@"drop table if exists t_student;"];
}

- (void)createDatabaseQueue {
    int age1 = arc4random_uniform(100);
    int age2 = arc4random_uniform(100);
    int age3 = arc4random_uniform(100);
    
    NSString *name1 = [NSString stringWithFormat:@"chen - %d",age1];
    NSString *name2 = [NSString stringWithFormat:@"chen - %d",age2];
    NSString *name3 = [NSString stringWithFormat:@"chen - %d",age3];
    
    // 1.获得数据库文件的路径
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *fileName = [doc stringByAppendingPathComponent:@"student.sqlite"];
    //1.创建队列
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:fileName];
    
    __block bool whoopsSomethingWrongHappened = true;
    
    //2.把任务包装到事务里
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        whoopsSomethingWrongHappened = [db executeUpdate:@"insert into t_student(name,age) values (?,?);" withArgumentsInArray:@[name1,@(age1)]];
        whoopsSomethingWrongHappened = [db executeUpdate:@"insert into t_student(name,age) values (?,?);" withArgumentsInArray:@[name2,@(age2)]];
        whoopsSomethingWrongHappened = [db executeUpdate:@"insert into t_student(name,age) values (?,?);" withArgumentsInArray:@[name3,@(age3)]];
        
        // 如果有错误,则返回
        if (!whoopsSomethingWrongHappened) {
            *rollback = YES;
            return;
        }
    }];
}

- (void)picCacheModel {
    PicCacheModel *pic1 = [[PicCacheModel alloc]init];
    pic1.pic_name       = @"DefaultImage_0";
    pic1.pic_from_source = @"0";
    pic1.pic_path       = [NSString stringWithFormat:@"%@.png",pic1.pic_name];
    
    PicCacheModel *pic2 = [[PicCacheModel alloc]init];
    pic2.pic_name       = @"DefaultImage_1";
    pic2.pic_from_source = @"0";
    pic2.pic_path       = [NSString stringWithFormat:@"%@.png",pic2.pic_name];
    
    
    PicCacheModel *pic3 = [[PicCacheModel alloc]init];
    pic3.pic_name       = @"DefaultImage_2";
    pic3.pic_from_source = @"0";
    pic3.pic_path       = [NSString stringWithFormat:@"%@.png",pic3.pic_name];
    
    [pic1 saveOrUpdate];
    [pic2 saveOrUpdate];
    [pic3 saveOrUpdate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
