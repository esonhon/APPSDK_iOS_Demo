//
//  OperateViewController.m
//  BLAPPSDKDemo
//
//  Created by 朱俊杰 on 16/8/1.
//  Copyright © 2016年 BroadLink. All rights reserved.
//
#import <sys/sysctl.h>
#import <netinet/in.h>
#import <net/if.h>
#import <netdb.h>
#import <sys/socket.h>
#import <arpa/inet.h>

#import "DeviceDB.h"
#import "OperateViewController.h"
#import "DataPassthoughViewController.h"
#import "DNAControlViewController.h"
#import "DeviceWebControlViewController.h"

#import "BLStatusBar.h"
#import "AppDelegate.h"
#import "AppMacro.h"
#import "SSZipArchive.h"
#import "SPViewController.h"
#import "RMViewController.h"
#import "A1ViewController.h"
#import "GateWayViewController.h"
#import "GeneralTimerControlView.h"
#import "FastconViewController.h"

@interface OperateViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, weak)NSTimer *stateTimer;
@property (nonatomic, strong)NSArray *operateButtonArray;
@property (nonatomic, copy)NSArray *configArray;
@property (weak, nonatomic) IBOutlet UITableView *operateTableView;
@end

@implementation OperateViewController {
    BLController *_blController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.operateTableView.delegate = self;
    self.operateTableView.dataSource = self;
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _blController = delegate.let.controller;
    
    UILabel *nameLabel = (UILabel *)[self.view viewWithTag:101];
    nameLabel.text = [nameLabel.text stringByAppendingString:[_device getName]];
    
    UILabel *didLabel = (UILabel *)[self.view viewWithTag:102];
    didLabel.text = [didLabel.text stringByAppendingString:[_device getDid]];
    
    UILabel *pidLabel = (UILabel *)[self.view viewWithTag:103];
    pidLabel.text = [pidLabel.text stringByAppendingString:[_device getPid]];
    
    UILabel *macLabel = (UILabel *)[self.view viewWithTag:104];
    macLabel.text = [macLabel.text stringByAppendingString:[_device getMac]];
    
    UILabel *netstateLabel = (UILabel *)[self.view viewWithTag:105];
    netstateLabel.text = [netstateLabel.text stringByAppendingString:@"Getting..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        //        [self copyCordovaJsToUIPathWithFileName:DNAKIT_CORVODA_JS_FILE];
    });
    
    _operateButtonArray = @[@"DNA Control",
                            @"Data Passthough",
                            @"General Timer",
                            @"GateWay Control",
                            @"Fastcon No Config",
                            @"Server Time",
                            @"query DeviceData",
                            @"Device Pair"
                            ];
    
    _configArray = [NSArray array];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    if (![_stateTimer isValid]) {
        __weak typeof(self) weakSelf = self;
        _stateTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f repeats:YES block:^(NSTimer * _Nonnull timer) {
            [weakSelf networkState];
        }];
        [_stateTimer fire];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    if ([_stateTimer isValid]) {
        [_stateTimer invalidate];
        _stateTimer = nil;
    }
}

#pragma mark - table delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_operateButtonArray count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellIdentifier = @"OPERATE TABLEVIEW";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = _operateButtonArray[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            [self dnaControl];
            break;
        case 1:
            [self dataPassthough];
            break;
        case 2:
            [self generalTimerControl];
            break;
        case 3:
            [self GateWayControl];
            break;
        case 4:
            [self fastconNoConfig];
            break;
        case 5:
            [self getServerTime];
            break;
        case 6:
            [self queryDeviceData];
            break;
        case 7:
            [self devicePair];
            break;
        default:
            break;
    }
}


#pragma mark - private method
- (void)networkState {
    BLDeviceStatusEnum state = [_blController queryDeviceState:[_device getDid]];
    NSString *stateString = @"State UnKown";
    switch (state) {
        case BL_DEVICE_STATE_LAN:
            stateString = @"LAN";
            break;
        case BL_DEVICE_STATE_REMOTE:
            stateString = @"REMOTE";
            break;
        case BL_DEVICE_STATE_OFFLINE:
            stateString = @"OFFLINE";
            break;
        default:
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *netstateLabel = (UILabel *)[self.view viewWithTag:105];
        netstateLabel.text = [NSString stringWithFormat:@"NetState:%@", stateString];
    });
}



- (void)dataPassthough {
    [self performSegueWithIdentifier:@"DataPassthoughView" sender:nil];
}

- (void)dnaControl {
    //是否下载了脚本，需要先下载脚本才能控制设备
    [self isDownloadScript];
    [self performSegueWithIdentifier:@"DNAControlView" sender:nil];
}

- (void)SPControl {
    [self isDownloadScript];
    NSString *ProfileStr = [self getDeviceProfile];
    if([ProfileStr isEqualToString:SMART_SP]){
        [self performSegueWithIdentifier:@"SPminiControlView" sender:nil];
    }else{
        [BLStatusBar showTipMessageWithStatus:@"Not SP device"];
    }
}

- (void)RMControl {
    [self isDownloadScript];
    NSString *ProfileStr = [self getDeviceProfile];
    if([ProfileStr isEqualToString:SMART_RM]){
        [self performSegueWithIdentifier:@"RMminiControlView" sender:nil];
    }else{
        [BLStatusBar showTipMessageWithStatus:@"Not RM device"];
    }
}

- (void)A1Control {
    [self isDownloadScript];
    NSString *ProfileStr = [self getDeviceProfile];
    if([ProfileStr isEqualToString:SMART_A1]){
        [self performSegueWithIdentifier:@"A1ControlView" sender:nil];
    }else{
        [BLStatusBar showTipMessageWithStatus:@"Not A1 device"];
    }
}

- (void)GateWayControl {
    [self isDownloadScript];
    [self performSegueWithIdentifier:@"GateWayControlView" sender:nil];
}

- (void)queryDeviceData {
    BLBaseBodyResult *result = [_blController queryDeviceDataWithDid:[_device getDid] familyId:@"" startTime:@"2018-03-26_17:00:00" endTime:@"2018-03-27_22:00:00" type:@"fw_spminielec_v1"];
    if ([result succeed]) {
        _resultText.text = [NSString stringWithFormat:@"responseBody : %@", result.responseBody];
    } else {
        _resultText.text = [NSString stringWithFormat:@"Code(%ld) Msg(%@)", (long)result.getError, result.getMsg];
    }
    NSLog(@"queryDeviceDataResult%@",result.responseBody);
}

- (NSString *)getDeviceProfile {
    BLProfileStringResult *result = [_blController queryProfile:[_device getDid]];
    static NSString *ProfileStr;
    if ([result succeed]) {
        NSString *ProfileStr = [result getProfile];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[ProfileStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        NSArray *srvStrArray = dic[@"srvs"];
        ProfileStr = srvStrArray[0];
        return ProfileStr;
    }
    return ProfileStr;
}

- (void)isDownloadScript {
    NSString *profileFile = [_blController queryScriptFileName:[self.device getPid]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:profileFile]) {
        [BLStatusBar showTipMessageWithStatus:@"Please download script first!"];
        return;
    }
}

- (void)webViewControl {
    if ([self copyCordovaJsToUIPathWithFileName:DNAKIT_CORVODA_JS_FILE] ) {
        [self performSegueWithIdentifier:@"DeviceWebControlView" sender:nil];
    }
}

- (void)getServerTime {
    [_blController updateDeviceInfo:self.device.did name:@"Fastcon-Device" lock:NO];
    BLDeviceTimeResult *result = [_blController queryDeviceTime:self.device.did];
    if ([result succeed]) {
        _resultText.text = [NSString stringWithFormat:@"Time:%@ diff:%ld", result.time, result.difftime];
    } else {
        _resultText.text = [NSString stringWithFormat:@"Code(%ld) Msg(%@)", (long)result.getError, result.getMsg];
    }
}


- (void)generalTimerControl {
    [self performSegueWithIdentifier:@"generalTimerControlView" sender:nil];
}

- (void)devicePair {
    BLPairResult *result = [_blController pairWithDevice:_device];
    _resultText.text = [NSString stringWithFormat:@"id:%ld,key:%@",(long)result.getId,result.getKey];
    if ([result succeed]) {
        //Update Device Info
        _device.controlId = result.getId;
        _device.controlKey = result.getKey;
        [[DeviceDB sharedOperateDB] updateSqlWithDevice:_device];
        //addDevice again
        [_blController addDevice:_device];
    }
    
}

- (void)fastconNoConfig {
    [self performSegueWithIdentifier:@"fastconControlView" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"DataPassthoughView"]) {
        UIViewController *target = segue.destinationViewController;
        if ([target isKindOfClass:[DataPassthoughViewController class]]) {
            DataPassthoughViewController* vc = (DataPassthoughViewController *)target;
            vc.device = _device;
        }
    } else if ([segue.identifier isEqualToString:@"DNAControlView"]) {
        UIViewController *target = segue.destinationViewController;
        if ([target isKindOfClass:[DNAControlViewController class]]) {
            DNAControlViewController* vc = (DNAControlViewController *)target;
            vc.device = _device;
        }
    } else if ([segue.identifier isEqualToString:@"DeviceWebControlView"]) {
        UIViewController *target = segue.destinationViewController;
        if ([target isKindOfClass:[DeviceWebControlViewController class]]) {
            DeviceWebControlViewController* vc = (DeviceWebControlViewController *)target;
            vc.selectDevice = _device;
        }
    } else if ([segue.identifier isEqualToString:@"SPminiControlView"]) {
        UIViewController *target = segue.destinationViewController;
        if ([target isKindOfClass:[SPViewController class]]) {
            SPViewController* vc = (SPViewController *)target;
            vc.device = _device;
        }
    }else if ([segue.identifier isEqualToString:@"RMminiControlView"]) {
        UIViewController *target = segue.destinationViewController;
        if ([target isKindOfClass:[RMViewController class]]) {
            RMViewController* vc = (RMViewController *)target;
            vc.device = _device;
        }
    }else if ([segue.identifier isEqualToString:@"A1ControlView"]) {
        UIViewController *target = segue.destinationViewController;
        if ([target isKindOfClass:[A1ViewController class]]) {
            A1ViewController* vc = (A1ViewController *)target;
            vc.device = _device;
        }
    }else if ([segue.identifier isEqualToString:@"GateWayControlView"]) {
        UIViewController *target = segue.destinationViewController;
        if ([target isKindOfClass:[GateWayViewController class]]) {
            GateWayViewController* vc = (GateWayViewController *)target;
            vc.device = _device;
        }
    }else if ([segue.identifier isEqualToString:@"generalTimerControlView"]) {
        UIViewController *target = segue.destinationViewController;
        if ([target isKindOfClass:[GeneralTimerControlView class]]) {
            GeneralTimerControlView* vc = (GeneralTimerControlView *)target;
            vc.device = _device;
        }
    }else if ([segue.identifier isEqualToString:@"fastconControlView"]) {
        UIViewController *target = segue.destinationViewController;
        if ([target isKindOfClass:[FastconViewController class]]) {
            FastconViewController* vc = (FastconViewController *)target;
            vc.device = _device;
        }
    }
}

- (BOOL)copyCordovaJsToUIPathWithFileName:(NSString*)fileName {
    NSString *uiPath = [[_blController queryUIPath:[_device getPid]] stringByDeletingLastPathComponent];  //  ../Let/ui/
    NSString *fullPathFileName = [uiPath stringByAppendingPathComponent:fileName];  // ../Let/ui/fileName
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:fullPathFileName] == NO) {
        NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
        NSError *error;
        BOOL success = [fileManager copyItemAtPath:path toPath:fullPathFileName error:&error];
        if (success) {
            NSLog(@"%@ copy success",fileName);
            return YES;
        } else {
            NSLog(@"%@ copy failed",fileName);
            return NO;
        }
    }
    
    return YES;
}


@end
