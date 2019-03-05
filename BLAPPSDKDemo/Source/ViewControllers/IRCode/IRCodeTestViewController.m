//
//  IRCodeTestViewController.m
//  BLAPPSDKDemo
//
//  Created by zjjllj on 2017/2/24.
//  Copyright © 2017年 BroadLink. All rights reserved.
//

#import "IRCodeTestViewController.h"
#import <BLLetIRCode/BLLetIRCode.h>

#import "BLStatusBar.h"
#import "CateGoriesTableViewController.h"
#import "AKeyToIdentifyViewController.h"

@implementation SubAreaInfo
- (instancetype)initWithDic: (NSDictionary *)dic {
    self = [super init];
    if (self) {
        _locateid = [dic[@"locateid"] integerValue];
        _levelid = [dic[@"levelid"] integerValue];
        _isleaf = [dic[@"isleaf"] integerValue];
        _status = dic[@"status"];
        _name = dic[@"name"];
    }
    return self;
}
@end

@interface IRCodeTestViewController ()

@property (nonatomic, strong) NSArray *testList;
@property (nonatomic, strong) BLController *blcontroller;
@property (nonatomic, strong) BLIRCode *blircode;
@property (nonatomic, strong) NSString *ircodeString;

@property (nonatomic, strong) NSString *downloadUrl;
@property (nonatomic, strong) NSString *randkey;
@property (nonatomic, strong) NSString *savePath;

@property (nonatomic, assign) NSUInteger locateid;
@property (nonatomic, assign) NSUInteger isleaf;
@property (nonatomic, assign) NSUInteger providerid;
@property(nonatomic, assign) NSInteger devtype;
@property(nonatomic, strong) NSArray<SubAreaInfo *> *subAreainfo;
@end

@implementation IRCodeTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.locateid = 27;
    self.providerid = 0;
    self.isleaf = 0;
    
    self.ircodeString = @"2600ca008d950c3b0f1410380e3a0d160e160d3b0d150e150e3910150d160d3a0f36101411380d150f3a0e390d3910370f150f38103a0d3a0e1211140f1411121038101310150f3710380e390e150f160d160e1410140f131113101310380e3b0f351137123611ad8e9210370f1511370e390f140f1410380f1311130f39101211130f390f380f150f390f1310380f3810380f380f141038103710380f1411121014101310380f14101310380f3810381013101311121014101211131014101310370f3910361138103710000d05";
    
    
    self.blcontroller = [BLLet sharedLet].controller;
    self.blircode = [BLIRCode sharedIrdaCode];
    [self.blircode requestIRCodeDeviceTypesCompletionHandler:^(BLBaseBodyResult * _Nonnull result) {
        NSLog(@"result:%@",result.msg);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)button:(UIButton *)sender {
    if (sender.tag == 100) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AC Code selection" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *CateGories = [UIAlertAction actionWithTitle:@"Brand selection" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.devtype = BL_IRCODE_DEVICE_AC;
            [self performSegueWithIdentifier:@"CateGoriesTableView" sender:nil];
        }];
        UIAlertAction *keyIdentify = [UIAlertAction actionWithTitle:@"Code one key recognition" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self performSegueWithIdentifier:@"aKeyToIdentify" sender:nil];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
        [alertController addAction:CateGories];
        [alertController addAction:keyIdentify];
        [self presentViewController:alertController animated:YES completion:nil];
    }else if (sender.tag == 101) {
        _devtype = BL_IRCODE_DEVICE_TV;
        [self performSegueWithIdentifier:@"CateGoriesTableView" sender:nil];
    }else if (sender.tag == 102) {
        _devtype = BL_IRCODE_DEVICE_TV_BOX;
        [self selectSubAreaLocateid];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CateGoriesTableView"]) {
        UIViewController *target = segue.destinationViewController;
        if ([target isKindOfClass:[CateGoriesTableViewController class]]) {
            CateGoriesTableViewController* opVC = (CateGoriesTableViewController *)target;
            opVC.device = self.device;
            opVC.devtype = _devtype;
            if (_devtype == BL_IRCODE_DEVICE_TV_BOX) {
                opVC.subAreainfo = (SubAreaInfo *)sender;
            }
        }
    }else if ([segue.identifier isEqualToString:@"aKeyToIdentify"]) {
        UIViewController *target = segue.destinationViewController;
        if ([target isKindOfClass:[AKeyToIdentifyViewController class]]) {
            AKeyToIdentifyViewController* opVC = (AKeyToIdentifyViewController *)target;
            opVC.device = self.device;
        }
    }
}

#pragma mark -
- (void)selectSubAreaLocateid{
    SubAreaInfo *subAreainfo = [[SubAreaInfo alloc]init];
    subAreainfo.isleaf = 0;
    subAreainfo.locateid = 0;
    [self querySubAreaLocateid:subAreainfo];
}

- (void)querySubAreaLocateid:(SubAreaInfo *)subAreainfo {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (subAreainfo.isleaf != 1) {
            [self.blircode requestSubAreaWithLocateid:subAreainfo.locateid completionHandler:^(BLBaseBodyResult * _Nonnull result) {
                NSLog(@"statue:%ld msg:%@", (long)result.error, result.msg);
                if ([result succeed]) {
                    NSLog(@"response:%@", result.responseBody);
                    NSData *jsonData = [result.responseBody dataUsingEncoding:NSUTF8StringEncoding];
                    NSError *err;
                    NSDictionary *responseBodydic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                                    options:NSJSONReadingMutableContainers
                                                                                      error:&err];
                    NSMutableArray *array = [NSMutableArray new];
                    for (NSDictionary *dic in responseBodydic[@"subareainfo"]) {
                        [array addObject: [[SubAreaInfo alloc] initWithDic:dic]];
                    }
                    self->_subAreainfo = array;
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Regional choice" message:@"Select country or region" preferredStyle:UIAlertControllerStyleActionSheet];
                    for (SubAreaInfo *subAreainfo in self->_subAreainfo) {
                        UIAlertAction *archiveAction = [UIAlertAction actionWithTitle:subAreainfo.name style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [self querySubAreaLocateid:subAreainfo];
                        }];
                        [alertController addAction:archiveAction];
                    }
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [BLStatusBar showTipMessageWithStatus:result.msg];
                    });
                }
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"CateGoriesTableView" sender:subAreainfo];
            });
        }

    });
    
}



@end
