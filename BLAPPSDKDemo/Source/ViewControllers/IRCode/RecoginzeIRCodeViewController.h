//
//  RecoginzeIRCodeViewController.h
//  BLAPPSDKDemo
//
//  Created by 白洪坤 on 2017/8/14.
//  Copyright © 2017年 BroadLink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProductModelsTableViewController.h"

@class Model;
@class BLDNADevice;
@interface RecoginzeIRCodeViewController : UIViewController
@property (strong, nonatomic) BLDNADevice *device;
@property (nonatomic, strong) NSString *downloadUrl;
@property (nonatomic, strong) NSString *randkey;
@property (nonatomic, strong) NSString *savePath;
@property (nonatomic, strong) downloadInfo *downloadinfo;
@end
