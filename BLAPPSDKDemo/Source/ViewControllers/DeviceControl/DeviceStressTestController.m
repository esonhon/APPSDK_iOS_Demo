//
//  DeviceStressTestController.m
//  BLAPPSDKDemo
//
//  Created by admin on 2019/4/9.
//  Copyright © 2019 BroadLink. All rights reserved.
//

#import "DeviceStressTestController.h"

#import "BLStatusBar.h"
#import "BLDeviceService.h"

@interface DeviceStressTestController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITextView *resultText;
@property (weak, nonatomic) IBOutlet UITableView *cmdTable;

@property (nonatomic, strong) NSMutableArray *cmdList;
@property (nonatomic, assign) NSUInteger recycleTimes;

@property (nonatomic, strong) NSString *logfile;
@property (nonatomic, strong) NSDateFormatter *formatter;

@end

@implementation DeviceStressTestController

+ (instancetype)viewController {
    DeviceStressTestController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.recycleTimes = 1;
    self.cmdList = [NSMutableArray arrayWithCapacity:0];
    self.cmdTable.delegate = self;
    self.cmdTable.dataSource = self;
    [self setExtraCellLineHidden:self.cmdTable];
    
    self.formatter = [[NSDateFormatter alloc] init];
    [self.formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    [self.formatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
}

- (IBAction)buttonClick:(UIButton *)sender {
    
    switch (sender.tag) {
        case 100:
            [self showCmdInputView];
            break;
        case 102:
            [self startStressTest];
            break;
        case 103:
            [self stopStressTest];
            break;
        default:
            break;
    }
}

- (BOOL)createStressTestLogFile {
    
    //将NSlog打印信息保存到Document目录下的Log文件夹下
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Log"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExists = [fileManager fileExistsAtPath:logDirectory];
    if (!fileExists) {
        [fileManager createDirectoryAtPath:logDirectory  withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    //每次启动后都保存一个新的日志文件中
    NSString *dateStr = [self.formatter stringFromDate:[NSDate date]];
    self.logfile = [logDirectory stringByAppendingFormat:@"/%@.log",dateStr];
    
    BOOL isSuccess = [fileManager createFileAtPath:self.logfile contents:nil attributes:nil];
    if (isSuccess) {
        NSLog(@"createStressTestLogFile success");
    } else {
        NSLog(@"createStressTestLogFile fail");
    }
    
    return isSuccess;
}

- (void)writeLogToFileWithString:(NSString *)log {
    
    if ([BLCommonTools isEmpty:log]) {
        return;
    }
    
    NSString *dateStr = [self.formatter stringFromDate:[NSDate date]];
    NSString *input = [NSString stringWithFormat:@"%@ :\n %@\n\n\n", dateStr, log];
    
    NSFileHandle *outFile = [NSFileHandle fileHandleForWritingAtPath:self.logfile];
    [outFile seekToEndOfFile];
    [outFile writeData:[input dataUsingEncoding:NSUTF8StringEncoding]];
    [outFile closeFile];
    
}

- (void)showTextResult:(NSArray *)infos totalString:(NSString *)totalString {
    
    NSMutableString *showString = [[NSMutableString alloc] initWithString:totalString];
    
    for (int i = 0; i < infos.count; i++) {
        NSDictionary *cmdResult = infos[i];
        NSString *result = [NSString stringWithFormat:@"\n\nCmd%d : total %d, success %d, failed %d",
                            i, [cmdResult[@"total"] intValue], [cmdResult[@"success"] intValue], [cmdResult[@"failed"] intValue]];
        
        [showString appendString:result];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.resultText.text = showString;
    });
    
}

- (void)doStressTest {
    BLController *controller = [BLLet sharedLet].controller;
    BLDeviceService *deviceService = [BLDeviceService sharedDeviceService];
    
    NSMutableArray *cmdResultArray = [NSMutableArray arrayWithCapacity:self.cmdList.count];
    [self createStressTestLogFile];
    [self writeLogToFileWithString:@"doStressTest start!!!"];
    
    for (int k = 0; k < self.recycleTimes; k++) {
        NSString *totalString = [NSString stringWithFormat:@"Recycle Total %ld, now %d", (long)self.recycleTimes, k+1];
        
        for (int i = 0; i < self.cmdList.count; i++) {
            NSDictionary *cmdDic = self.cmdList[i];
            
            NSString *did = cmdDic[@"did"];
            NSString *cmd = cmdDic[@"cmd"];
            NSString *dataStr = cmdDic[@"data"];
            int count = [cmdDic[@"count"] intValue];
            int interval = [cmdDic[@"interval"] intValue];
            int delay = [cmdDic[@"delay"] intValue];
            
            BLDNADevice *device = [deviceService.manageDevices objectForKey:did];
            if (!device) {
                [self writeLogToFileWithString:[NSString stringWithFormat:@"Can not find device %@", did]];
                continue;
            }
            
            NSString *gatewayDid = device.did;
            NSString *subDeviceDid;
            if (![BLCommonTools isEmpty:device.pDid]) {
                gatewayDid = device.pDid;
                subDeviceDid = device.did;
                
                BLDNADevice *gatewayDevice = [deviceService.manageDevices objectForKey:gatewayDid];
                if (!gatewayDevice) {
                    [self writeLogToFileWithString:[NSString stringWithFormat:@"Can not find gateway device %@", gatewayDid]];
                    continue;
                }
            }
            
            for (int j = 0; j < count; j++) {
                
                [self writeLogToFileWithString:[NSString stringWithFormat:@"cmd:%@ times:%d", cmdDic, j]];
                NSString *result = [controller dnaControl:gatewayDid subDevDid:subDeviceDid dataStr:dataStr command:cmd scriptPath:nil sendcount:1];
                [self writeLogToFileWithString:[NSString stringWithFormat:@"result:%@", result]];
                
                NSDictionary *retDic = [BLCommonTools deserializeMessageJSON:result];
                int status = [retDic[@"status"] intValue];
                
                NSDictionary *cmdResult;
                
                if (i < cmdResultArray.count) {
                    cmdResult = cmdResultArray[i];
                }
                
                int success = 0;
                int failed = 0;
                if (cmdResult) {
                    success = [cmdResult[@"success"] intValue];
                    failed = [cmdResult[@"failed"] intValue];
                }
                
                if (status == 0) {
                    success++;
                } else {
                    failed++;
                }
                
                int total = success + failed;
                cmdResult = @{
                              @"index":@(i),
                              @"total":@(total),
                              @"success":@(success),
                              @"failed":@(failed)
                              };
                
                if (i < cmdResultArray.count) {
                    cmdResultArray[i] = cmdResult;
                } else {
                    [cmdResultArray addObject:cmdResult];
                }

                [self showTextResult:cmdResultArray totalString:totalString];
                
                usleep(interval * 1000);
            }
            usleep(delay * 1000);
        }
    }
    
    [self writeLogToFileWithString:self.resultText.text];
    [self writeLogToFileWithString:@"doStressTest over!!!"];
}

- (void)startStressTest {
    if ([BLCommonTools isEmptyArray:self.cmdList]) {
        [BLStatusBar showTipMessageWithStatus:@"Please input command first!!!"];
        return;
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Times input" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = @"";
        textField.placeholder = @"Recycle Times";
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSString *timesStr = alertController.textFields.firstObject.text;
        if (![BLCommonTools isEmpty:timesStr]) {
            self.recycleTimes = [timesStr integerValue];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self doStressTest];
        });
        
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)stopStressTest {
    self.recycleTimes = 0;
    [self writeLogToFileWithString:self.resultText.text];
    [self writeLogToFileWithString:@"stopStressTest!!!"];
    self.logfile = nil;
}

- (void)showCmdInputView {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Cmd input" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = @"";
        textField.placeholder = @"Device did";
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = @"";
        textField.placeholder = @"Cmd. Default : dev_ctrl";
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = @"{\"vals\":[[{\"val\":1,\"idx\":1}]],\"act\":\"set\",\"params\":[\"pwr\"],\"prop\":\"stdctrl\"}";
        textField.placeholder = @"Data String";
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = @"";
        textField.placeholder = @"Send Count. Default : 1";
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = @"";
        textField.placeholder = @"Interval(/ms). Default : 1000";
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = @"";
        textField.placeholder = @"Delay(/ms). Default : 1000";
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *did = alertController.textFields.firstObject.text;
        NSString *cmdStr = alertController.textFields[1].text;
        NSString *dataStr = alertController.textFields[2].text;
        NSString *sendCountStr = alertController.textFields[3].text;
        NSString *intervalStr = alertController.textFields[4].text;
        NSString *delayStr = alertController.textFields[5].text;
        
        if ([BLCommonTools isEmpty:cmdStr]) {
            cmdStr = @"dev_ctrl";
        }
        
        int sendCount = 1;
        if (![BLCommonTools isEmpty:sendCountStr]) {
            sendCount = [sendCountStr intValue];
        }
        
        int interval = 1000;
        if (![BLCommonTools isEmpty:intervalStr]) {
            interval = [intervalStr intValue];
        }
        
        int delay = 1000;
        if (![BLCommonTools isEmpty:delayStr]) {
            delay = [delayStr intValue];
        }
        
        NSDictionary *cmdDic = @{
                                 @"did":did,
                                 @"cmd":cmdStr,
                                 @"data":dataStr,
                                 @"count":@(sendCount),
                                 @"interval":@(interval),
                                 @"delay":@(delay)
                                 };
        
        [self.cmdList addObject:cmdDic];
        [self.cmdTable reloadData];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cmdList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120.0;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString* cellIdentifier = @"STRESS_CMD_CELL";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    NSDictionary *cmdDic = self.cmdList[indexPath.row];
    UILabel *label = (UILabel *)[cell viewWithTag:200];
    label.text = [BLCommonTools serializeMessage:cmdDic];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.cmdList removeObjectAtIndex:indexPath.row];
    }
}

@end
