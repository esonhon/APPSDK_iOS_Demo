//
//  WebSocketManagerViewController.m
//  BLAPPSDKDemo
//
//  Created by hongkun.bai on 2019/11/20.
//  Copyright © 2019 BroadLink. All rights reserved.
//

#import "WebSocketManagerViewController.h"
#import "BLDeviceService.h"
#import <BLSWebScoket/BLSWebScoket.h>
#import <BLSFamily/BLSFamily.h>
@interface WebSocketManagerViewController ()<BLWebSocketDelegate>
@property (weak, nonatomic) IBOutlet UITextField *linkUrRLText;
@property (weak, nonatomic) IBOutlet UITextView *resultView;
@property (weak, nonatomic) IBOutlet UITextView *sendView;
//@property (nonatomic, strong) BLSWebSocketClient *webSocket;
@property (nonatomic, strong) NSMutableArray *familyIds;
@property (nonatomic, copy) NSMutableDictionary *socketClients;
@end

@implementation WebSocketManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getAllSceneInfo];
    [BLSWebSocketManager shareManagerWithRelayType:@"share"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[BLSWebSocketManager shareManager] destroyAllLink];
}

- (void)getAllSceneInfo {
    BLSFamilyManager *manager = [BLSFamilyManager sharedFamily];
    [manager getScenesWithCompletionHandler:^(BLSQueryScenesResult * _Nonnull result) {
        for (BLSSceneInfo *sceneInfo in result.scenes) {
            [self.familyIds addObject:sceneInfo.familyId];
        }
    }];
}

- (IBAction)action:(UIButton *)sender {
    BLDeviceService *deviceService = [BLDeviceService sharedDeviceService];

    if (sender.tag == 101) {
        //设备推送订阅
        [self devPushSubscription:[deviceService.manageDevices allValues]];
    }else if (sender.tag == 102) {
        //设备推送取消订阅
        [self devPushUnSubscription:[deviceService.manageDevices allValues]];
    }else if (sender.tag == 103) {
        //查询设备推送订阅
        [self devPushQuery];
    }else if (sender.tag == 104) {
        //场景状态订阅
        [self senceStatusSubscription:self.familyIds];
    }else if (sender.tag == 105) {
        //场景状态取消订阅
        [self senceStatusUnSubscription:self.familyIds];
    }else if (sender.tag == 106) {
        //查询场景推送订阅
        [self senceStatusQuery];
    }else if (sender.tag == 107) {
        //查询长连接URL
        BLSWebScoketUrlResult *urlResult = [[BLSWebSocketManager shareManager] apprelayGetUrl];
        for (NSString *urlPath in urlResult.data.url) {
            self.linkUrRLText.text = urlPath;
        }
    }else if (sender.tag == 108) {
        //创建长连接
        BLSWebSocketClient *webSocket = [[BLSWebSocketManager shareManager] createLink:self.linkUrRLText.text];
        webSocket.delegate = self;
        [self.socketClients setValue:[NSString stringWithFormat:@"%lu",(unsigned long)webSocket.hash] forKey:self.linkUrRLText.text];
    }else if (sender.tag == 109) {
        //发送长连接消息
        NSString *sendString = self.sendView.text;
        [[self getWebSocketClient] sendMsg:sendString];
    }else if (sender.tag == 110) {
        //销毁长连接
        [[self getWebSocketClient] closeWebSocketActively];
    }
}

- (BLSWebSocketClient *)getWebSocketClient {
    NSString *hash = [self.socketClients objectForKey:self.linkUrRLText.text];
    BLSWebSocketClient *webSocket = [[BLSWebSocketManager shareManager] getWebSocketClientWithHash:hash];
    return webSocket;
}

- (void)didInitMessage:(id)message {
    if ([message isKindOfClass:[NSString class]]) {
        self.resultView.text = message;
    }
}

- (void)didReceiveMessage:(id)message {
    if ([message isKindOfClass:[NSString class]]) {
        self.resultView.text = message;
    }
}

- (void)didFailWithError:(NSError *)error {
    
}

- (void)didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    if ([reason isKindOfClass:[NSString class]]) {
        self.resultView.text = reason;
    }
}



//设备推送订阅
- (void)devPushSubscription:(NSArray<BLDNADevice *> *)devArray{
    NSTimeInterval nowTimeInvterval = [[NSDate date] timeIntervalSince1970];
    NSString *msgId = [NSString stringWithFormat:@"%@-%f", [BLConfigParam sharedConfigParam].userid, nowTimeInvterval];
    NSMutableArray *devList = [NSMutableArray arrayWithCapacity:0];
    for (BLDNADevice *device in devArray) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:0];
        NSString *endpointId = device.did;
        NSString *gatewayId = device.pDid;
        [dict setObject:endpointId forKey:@"endpointId"];
        if (![BLCommonTools isEmpty:gatewayId]) {
            [dict setObject:gatewayId forKey:@"gatewayId"];
        }
        
        [devList addObject:dict];
    }
    NSDictionary *tempDict = @{
        @"msgtype":@"sub",
        @"topic":@"devpush",
        @"messageid":msgId,
        @"data":@{
            @"devList":devList
        }
    };
       
    NSString *sendString = [tempDict BLS_modelToJSONString];
    self.sendView.text = sendString;
    
    NSString *hash = [self.socketClients objectForKey:self.linkUrRLText.text];
    BLSWebSocketClient *webSocket = [[BLSWebSocketManager shareManager] getWebSocketClientWithHash:hash];
    [webSocket sendMsg:sendString];
}



//取消设备推送订阅
- (void)devPushUnSubscription:(NSArray<BLDNADevice *> *)devArray{
    NSTimeInterval nowTimeInvterval = [[NSDate date] timeIntervalSince1970];
    NSString *msgId = [NSString stringWithFormat:@"%@-%f", [BLConfigParam sharedConfigParam].userid, nowTimeInvterval];
    NSMutableArray *devList = [NSMutableArray arrayWithCapacity:0];
    for (BLDNADevice *device in devArray) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:0];
        NSString *endpointId = device.did;
        NSString *gatewayId = device.pDid;
        [dict setObject:endpointId forKey:@"endpointId"];
        if (![BLCommonTools isEmpty:gatewayId]) {
            [dict setObject:gatewayId forKey:@"gatewayId"];
        }
        [devList addObject:dict];
    }
    NSDictionary *tempDict = @{
        @"msgtype":@"unsub",
        @"topic":@"devpush",
        @"messageid":msgId,
        @"data":@{
            @"devList":devList
        }
    };
       
    NSString *sendString = [tempDict BLS_modelToJSONString];
    self.sendView.text = sendString;
    
    [[self getWebSocketClient] sendMsg:sendString];
}

//查询设备推送订阅列表
- (void)devPushQuery{
    NSTimeInterval nowTimeInvterval = [[NSDate date] timeIntervalSince1970];
    NSString *msgId = [NSString stringWithFormat:@"%@-%f", [BLConfigParam sharedConfigParam].userid, nowTimeInvterval];
    NSDictionary *tempDict = @{
        @"msgtype":@"query",
        @"topic":@"devpush",
        @"messageid":msgId
    };
       
    NSString *sendString = [tempDict BLS_modelToJSONString];
    self.sendView.text = sendString;

    [[self getWebSocketClient] sendMsg:sendString];
}

//场景状态订阅
- (void)senceStatusSubscription:(NSArray<NSString *> *)familyIds{
    NSTimeInterval nowTimeInvterval = [[NSDate date] timeIntervalSince1970];
    NSString *msgId = [NSString stringWithFormat:@"%@-%f", [BLConfigParam sharedConfigParam].userid, nowTimeInvterval];
    NSMutableArray *familyList = [NSMutableArray arrayWithCapacity:0];
    for (NSString *familyId in familyIds) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:0];
        [dict setObject:familyId forKey:@"familyId"];
        
        [familyList addObject:dict];
    }
    NSDictionary *tempDict = @{
        @"msgtype":@"sub",
        @"topic":@"scenestatus",
        @"messageid":msgId,
        @"data":@{
            @"familyList":familyList
        }
    };
       
    NSString *sendString = [tempDict BLS_modelToJSONString];
    self.sendView.text = sendString;
    
    [[self getWebSocketClient] sendMsg:sendString];
}



//取消场景状态订阅
- (void)senceStatusUnSubscription:(NSArray<NSString *> *)familyIds{
    NSTimeInterval nowTimeInvterval = [[NSDate date] timeIntervalSince1970];
    NSString *msgId = [NSString stringWithFormat:@"%@-%f", [BLConfigParam sharedConfigParam].userid, nowTimeInvterval];
    NSMutableArray *familyList = [NSMutableArray arrayWithCapacity:0];
    for (NSString *familyId in familyIds) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:0];
        [dict setObject:familyId forKey:@"familyId"];
        [familyList addObject:dict];
    }
    NSDictionary *tempDict = @{
        @"msgtype":@"unsub",
        @"topic":@"scenestatus",
        @"messageid":msgId,
        @"data":@{
            @"devList":familyList
        }
    };
       
    NSString *sendString = [tempDict BLS_modelToJSONString];
    self.sendView.text = sendString;
    
    [[self getWebSocketClient] sendMsg:sendString];
}

//查询场景状态订阅列表
- (void)senceStatusQuery{
    NSTimeInterval nowTimeInvterval = [[NSDate date] timeIntervalSince1970];
    NSString *msgId = [NSString stringWithFormat:@"%@-%f", [BLConfigParam sharedConfigParam].userid, nowTimeInvterval];
    NSDictionary *tempDict = @{
        @"msgtype":@"query",
        @"topic":@"sencestatus",
        @"messageid":msgId
    };
       
    NSString *sendString = [tempDict BLS_modelToJSONString];
    self.sendView.text = sendString;
    
    [[self getWebSocketClient] sendMsg:sendString];
}

- (NSMutableArray *)familyIds {
    if (!_familyIds) {
        _familyIds = [[NSMutableArray alloc] init];
    }
    return _familyIds;
}

- (NSMutableDictionary *)socketClients {
    if (!_socketClients) {
        _socketClients = [[NSMutableDictionary alloc] init];
    }
    return _socketClients;
}
@end
