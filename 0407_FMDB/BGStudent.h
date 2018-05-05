//
//  BGStudent.h
//  0407_FMDB
//
//  Created by cs on 2018/4/7.
//  Copyright © 2018年 cs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BGStudent : NSObject

/** id */
@property(nonatomic, assign)int ID;
/** name */
@property(nonatomic, strong)NSString *name;
/** sex */
@property(nonatomic, strong)NSString *sex;
/** age */
@property(nonatomic, assign)int age;

@end
