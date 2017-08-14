//
//  AppDelegate.m
//  Voip
//
//  Created by A on 16/9/13.
//  Copyright © 2016年 A. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "CallViewController.h"
#import "Constant.h"
#import "PJSua.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "XMGAudioTool.h"
@interface AppDelegate ()
@property (nonatomic,strong)UIAlertView *phoneAlertView;
@property (nonatomic, assign) NSInteger phoneID;
@property (nonatomic,copy)NSString* sipName;//来电sip号
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    LoginViewController *login_vc = [[LoginViewController alloc] init];
    login_vc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"登录" image:[UIImage imageNamed:@"tab_main_unselected"] selectedImage:[UIImage imageNamed:@"tab_main_selected"]];
    CallViewController *call_vc = [[CallViewController alloc] init];
    call_vc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"呼叫" image:[UIImage imageNamed:@"tab_show_unselected"] selectedImage:[UIImage imageNamed:@"tab_show_selected"]];
    
    UITabBarController *tab_bar_vc = [[UITabBarController alloc] init];
    tab_bar_vc.viewControllers = [[NSArray alloc] initWithObjects:login_vc, call_vc, nil];
    
    self.window = [[UIWindow alloc] initWithFrame:screenBounds];
    [self.window makeKeyAndVisible];
    self.window.rootViewController = tab_bar_vc;
    
    //来电提醒
    [self incomingCall];
    
    
    return YES;
}

-(void)incomingCall
{
    NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
    [notiCenter addObserver:self selector:@selector(onReceiveIncomingCall:) name:PJSUAIncomingCallNotification object:nil];
    
    [notiCenter addObserver:self selector:@selector(onReceiveHangUpCall:) name:PJSUAHangUpCallNotification object:nil];
    
    
    
}

//挂断调用方法
- (void)onReceiveHangUpCall:(NSNotification *)notification {
    [XMGAudioTool stopMusicWithMusicName:@"来电铃声.mp3"];
    [self.phoneAlertView dismissWithClickedButtonIndex:0 animated:NO];
    
    
}

- (void)onReceiveIncomingCall:(NSNotification *)noti {
    
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            if (!granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:@"无法使用麦克风"
                                                message:@"请在iPhone的\"设置-隐私-麦克风\"中允许访问麦克风"
                                               delegate:self
                                      cancelButtonTitle:@"确认"
                                      otherButtonTitles:nil] show];
                });
            }
        }];
    }
    
    [XMGAudioTool playMusicWithMusicName:@"来电铃声.mp3"];
    
    // 强制设置为扬声器播放
    //    NSError *categoryError = nil;
    //    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&categoryError];
    //    [audioSession setActive:YES error:&categoryError];
    //    UInt32 doChangeDefault = 1;
    //    AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefault), &doChangeDefault);
    //
    
    // 强制设置为扬声器播放
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    
    NSArray *object =[noti object];
    self.phoneID = [object[0] integerValue];
    self.sipName=object[1];
    self.sipName =[self.sipName componentsSeparatedByString:@"\" <"][0];
    self.sipName=[self.sipName substringFromIndex:1];
    
    UIAlertView *phoneAlertView = [[UIAlertView alloc] initWithTitle:@"有来电" message:[NSString stringWithFormat:@"您有个新来电请接听%@",self.sipName] delegate:self cancelButtonTitle:nil otherButtonTitles:@"拒接", @"接听", nil];
    self.phoneAlertView=phoneAlertView;
    [phoneAlertView show];

    //本地通知有了来电
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.alertBody =  [NSString stringWithFormat:@"%@给您来电,点击查看详情",object[1]];
    //notification.applicationIconBadgeNumber = 1;
    // 通知被触发时播放的声音
    notification.soundName = UILocalNotificationDefaultSoundName;
    // 通知参数
    NSDictionary *userDict = [NSDictionary dictionaryWithObject:@"推送通知前台" forKey:@"key"];
    notification.userInfo = userDict;
    // ios8后，需要添加这个注册，才能得到授权
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationType type =  UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        // 通知重复提示的单位，可以是天、周、月
        notification.repeatInterval = NSCalendarUnitDay;
    }
    
    // 执行通知注册
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [XMGAudioTool stopMusicWithMusicName:@"来电铃声.mp3"];
    if (buttonIndex == 0) {
        [[PJSua sharedInstance] hangUp:self.phoneID];
    } else {
        
//        IncomingCallVC*callVC=[[IncomingCallVC alloc]init];
//        callVC.titleName=self.sipName;
//        callVC.phoneID=self.phoneID;
//        [self.window.rootViewController presentViewController:callVC animated:YES completion:nil];
        
    }
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
      [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[PJSua sharedInstance] unregister]; //向服务器发送退出登录
}

@end
