//
//  PicCacheModel.m
//  0407_FMDB
//
//  Created by cs on 2018/4/7.
//  Copyright © 2018年 cs. All rights reserved.
//

#import "PicCacheModel.h"

@implementation PicCacheModel

+ (NSArray *)transients
{
    return @[@"pic_name",@"pic_from_source",@"pic_path"];
}

@end
