//
//  ControlViewController.h
//  BLAPPSDKDemo
//
//  Created by 白洪坤 on 2017/8/9.
//  Copyright © 2017年 BroadLink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProductModelsTableViewController.h"
@class Model;
@class BLDNADevice;
@interface ControlViewController : UIViewController
@property (strong, nonatomic) BLDNADevice *device;
@property (nonatomic, strong) NSString *randkey;
@property (nonatomic, strong) NSString *savePath;
@end
