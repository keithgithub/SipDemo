//
//  LoginViewController.m
//  Voip
//
//  Created by A on 16/9/18.
//  Copyright © 2016年 A. All rights reserved.
//

#import "LoginViewController.h"
#import <pjlib.h>
#import <pjsua.h>
#import <pj/log.h>
#import "CallViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "PJSua.h"

#import "Constant.h"

@interface LoginViewController ()

@property (nonatomic, strong) UITextField *hostTextField;
@property (nonatomic, strong) UITextField *userTextField;
@property (nonatomic, strong) UITextField *pswdTextField;

@property (nonatomic, strong) UIButton *connectBtn;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self createSubviews];
    [self setDefaultText];
    
    [self registerNotification];
}

- (void)createSubviews {
    CGFloat margin = 15;
    CGFloat labelWidth = 80;
    CGFloat labelX = margin;
    
    CGFloat commonHeight = 30;
    CGFloat commonX = labelX + labelWidth + margin;
    CGFloat commonWidth = screenWidth - commonX - 2*margin;
    
    CGFloat startY = 30;
    
    self.hostTextField = [[UITextField alloc] initWithFrame:CGRectMake(commonX, startY, commonWidth, commonHeight)];
    self.hostTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.hostTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:self.hostTextField];
    
    UILabel *hostLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, startY, labelWidth, commonHeight)];
    hostLabel.text = @"域名或主机:";
    hostLabel.textAlignment = NSTextAlignmentRight;
    hostLabel.textColor = [UIColor blackColor];
    hostLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:hostLabel];
    
    self.userTextField = [[UITextField alloc] initWithFrame:CGRectMake(commonX, CGRectGetMaxY(self.hostTextField.frame) + margin, commonWidth, commonHeight)];
    self.userTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.userTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:self.userTextField];
    
    UILabel *userLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, CGRectGetMaxY(self.hostTextField.frame) + margin, labelWidth, commonHeight)];
    userLabel.text = @"用户名:";
    userLabel.textAlignment = NSTextAlignmentRight;
    userLabel.textColor = [UIColor blackColor];
    userLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:userLabel];
    
    self.pswdTextField = [[UITextField alloc] initWithFrame:CGRectMake(commonX, CGRectGetMaxY(self.userTextField.frame) + margin, commonWidth, commonHeight)];
    self.pswdTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.pswdTextField.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:self.pswdTextField];
    
    UILabel *pswdLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, CGRectGetMaxY(self.userTextField.frame) + margin, labelWidth, commonHeight)];
    pswdLabel.text = @"密码:";
    pswdLabel.textAlignment = NSTextAlignmentRight;
    pswdLabel.textColor = [UIColor blackColor];
    pswdLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:pswdLabel];
    
    CGFloat commonBtnH = 40;
    CGFloat connectBtnW = 80;
    CGFloat connectBtnX = screenWidth/2 - connectBtnW/2;
    CGFloat connectBtnY = CGRectGetMaxY(pswdLabel.frame) + margin;
    
    self.connectBtn = [[UIButton alloc] initWithFrame:CGRectMake(connectBtnX, connectBtnY, connectBtnW, commonBtnH)];
    [self.connectBtn addTarget:self action:@selector(onConnectBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.connectBtn setTitle:@"连接" forState:UIControlStateNormal];
    self.connectBtn.backgroundColor = [UIColor greenColor];
    [self.view addSubview:self.connectBtn];
}

- (void)onConnectBtnClicked {

    PJSua *pjsua = [PJSua sharedInstance];
    [pjsua registerToServer:self.hostTextField.text username:self.userTextField.text passwd:self.pswdTextField.text];
}

- (void)loginCompleted:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Succeeded"
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed"
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    });
}

- (void)onDisconnectBtnClicked {
    
    PJSua *pjsua = [PJSua sharedInstance];
    [pjsua unregister];
    
    [self.connectBtn setTitle:@"连接" forState:UIControlStateNormal];
    [self.connectBtn removeTarget:self action:@selector(onDisconnectBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.connectBtn addTarget:self action:@selector(onConnectBtnClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setDefaultText {
    
    if (isLocal) {
        self.hostTextField.text = @"192.168.3.147:5060";
        self.pswdTextField.text = @"123";
        if (isIphone4) {
            self.userTextField.text = @"test2";
        } else {
            self.userTextField.text = @"test";
        }
    } else {
//        self.hostTextField.text = @"172.16.11.203:5670";
      self.hostTextField.text = @"36.250.86.216:5670";

        self.pswdTextField.text = @"1234";
        if (isIphone4) {
            self.userTextField.text = @"1011";
        } else {
            self.userTextField.text = @"18098928416";
        }
    }
}

- (void)registerNotification {
    NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
    [notiCenter addObserver:self selector:@selector(onReceiveRegisterResult:) name:PJSUARegisterResultNotification object:nil];
}

- (void)onReceiveRegisterResult:(NSNotification *)notification {
    
    if ([[notification object] boolValue]) {
        [self.connectBtn setTitle:@"退出" forState:UIControlStateNormal];
        [self.connectBtn removeTarget:self action:@selector(onConnectBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.connectBtn addTarget:self action:@selector(onDisconnectBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [[[UIAlertView alloc] initWithTitle:nil message:@"登录错误" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
    }
    
    
    pjsua_acc_id acc_id = [notification.userInfo[@"acc_id"] intValue];
    [[NSUserDefaults standardUserDefaults] setInteger:acc_id forKey:@"login_account_id"];
    
    
    
    
}

//// 取消某个本地推送通知
//+ (void)cancelLocalNotificationWithKey:(NSString *)key {
//    // 获取所有本地通知数组
//    NSArray *localNotifications = [UIApplication sharedApplication].scheduledLocalNotifications;
//    
//    for (UILocalNotification *notification in localNotifications) {
//        NSDictionary *userInfo = notification.userInfo;
//        if (userInfo) {
//            // 根据设置通知参数时指定的key来获取通知参数
//            NSString *info = userInfo[key];
//            
//            // 如果找到需要取消的通知，则取消
//            if (info != nil) {
//                [[UIApplication sharedApplication] cancelLocalNotification:notification];
//                break;
//            }
//        }
//    }
//}

// 消失键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self.hostTextField resignFirstResponder];
    [self.userTextField resignFirstResponder];
    [self.pswdTextField resignFirstResponder];
    [self.hostTextField resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
