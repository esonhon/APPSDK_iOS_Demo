//
//  IRCodeDownloadInfo.h
//  BLAPPSDKDemo
//
//  Created by admin on 2019/3/26.
//  Copyright © 2019 BroadLink. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IRCodeDownloadInfo : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *downloadurl;
@property (nonatomic, copy) NSString *randkey;
@property (nonatomic, copy) NSString *fixkey;
@property (nonatomic, copy) NSString *savePath;
@property (nonatomic, assign) NSInteger brandId;
@property (nonatomic, assign) NSInteger devtype;

@end

NS_ASSUME_NONNULL_END
