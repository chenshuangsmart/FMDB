//
//  PicCacheModel.h
//  0407_FMDB
//
//  Created by cs on 2018/4/7.
//  Copyright © 2018年 cs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBBaseModel.h"

@interface PicCacheModel : DBBaseModel

/** name */
@property(nonatomic, strong)NSString *pic_name;
/** source */
@property(nonatomic, strong)NSString *pic_from_source;
/** path */
@property(nonatomic, strong)NSString *pic_path;
/** md5 */
@property(nonatomic, strong)NSString *pic_md5_str;

@end
