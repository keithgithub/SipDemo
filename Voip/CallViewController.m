//
//  CallViewController.m
//  Voip
//
//  Created by A on 16/9/18.
//  Copyright © 2016年 A. All rights reserved.
//

#import "CallViewController.h"
#import "Constant.h"
#import "PJSua.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface CallViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) UITextField *userTextField;
@property (nonatomic, strong) UITextField *hostTextField;
@property (nonatomic, assign) NSInteger phoneID;
@property (nonatomic, strong) UIButton *callBtn;
@property (nonatomic, strong) UIButton *hangUpBtn;

@property (nonatomic,strong)UIView *vid_preview;

@end

@implementation CallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    
    [self createSubviews];
    [self registerNotification];
    [self setDefaultText];
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
    self.userTextField.placeholder = @"被呼叫号码";
    [self.view addSubview:self.userTextField];
    
    
    UILabel *userLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, CGRectGetMaxY(self.hostTextField.frame) + margin, labelWidth, commonHeight)];
    userLabel.text = @"用户名:";
    userLabel.textAlignment = NSTextAlignmentRight;
    userLabel.textColor = [UIColor blackColor];
    userLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:userLabel];
    
    CGFloat commonBtnH = 40;
    CGFloat commonBtnW = 80;
    CGFloat commonBtnY = CGRectGetMaxY(self.userTextField.frame) + margin;
    
    CGFloat hangUpBtnX = screenWidth/4 - commonBtnW/2;
    CGFloat callBtnX = screenWidth/2 + screenWidth/4 - commonBtnW/2;
    
    self.callBtn = [[UIButton alloc] initWithFrame:CGRectMake(callBtnX, commonBtnY, commonBtnW, commonBtnH)];
    [self.callBtn addTarget:self action:@selector(onCallBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.callBtn setTitle:@"呼叫" forState:UIControlStateNormal];
    [self.view addSubview:self.callBtn];
    self.callBtn.backgroundColor = [UIColor greenColor];
    
    self.hangUpBtn = [[UIButton alloc] initWithFrame:CGRectMake(hangUpBtnX, commonBtnY, commonBtnW, commonBtnH)];
    [self.hangUpBtn addTarget:self action:@selector(onHangUpBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.hangUpBtn setTitle:@"挂断" forState:UIControlStateNormal];
    [self.view addSubview:self.hangUpBtn];
    self.hangUpBtn.backgroundColor = [UIColor greenColor];
}

- (void)setDefaultText {
    
    if (isLocal) {
        self.hostTextField.text = @"192.168.3.147:5060";
        if (isIphone4) {
            self.userTextField.text = @"test";
        } else {
            self.userTextField.text = @"test2";
        }
    } else {
        self.hostTextField.text = @"36.250.86.216:5670";
        if (isIphone4) {
            self.userTextField.text = @"80885";
        } else {
            self.userTextField.text = @"18098918416";
            //self.userTextField.text = @"13926549672"; // 庞总的号码
        }
    }
}

- (void)registerNotification {
    NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
    [notiCenter addObserver:self selector:@selector(onReceiveIncomingCall:) name:PJSUAIncomingCallNotification object:nil];
    [notiCenter addObserver:self selector:@selector(onReceiveHangUpCall:) name:PJSUAHangUpCallNotification object:nil];
    [notiCenter addObserver:self selector:@selector(displayVideo:) name:PJSUAShowVideoNotification object:nil];
    
    // 检测设备旋转状态
    [notiCenter addObserver:self selector:@selector(onOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)onOrientationChanged:(NSNotification *)noti {
    
    UIDeviceOrientation dev_ori = [[UIDevice currentDevice] orientation];
    [[PJSua sharedInstance] setVideoCaptureOrientation:dev_ori];
    
//      [[PJSua sharedInstance] setVideoCaptureOrientation:UIDeviceOrientationPortrait];
    
    
}

- (void)onReceiveIncomingCall:(NSNotification *)noti {
    //来电铃声响起
    CFBundleRef mainBundle;
    //@typedef SystemSoundID@abstract SystemSoundIDs是由系统声音客户机应用程序的回放AudioFile提供
    SystemSoundID soundFileObject;
    mainBundle = CFBundleGetMainBundle();
    // Get the URL to the sound file to play
    CFURLRef soundFileURLRef  = CFBundleCopyResourceURL (mainBundle,CFSTR ("phone"),CFSTR ("caf"),NULL);
    AudioServicesCreateSystemSoundID(soundFileURLRef,&soundFileObject);
    // Add sound completion callback
    //循环
    // AudioServicesAddSystemSoundCompletion (soundFileObject, NULL, NULL,   completionCallback,(__bridge void*) self);
    // Play the audio
    AudioServicesPlaySystemSound(soundFileObject);
    
    // 强制设置为扬声器播放
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    
    
    NSArray *object =[noti object];
    self.phoneID = [object[0] integerValue];
    
    UIAlertView *phoneAlertView = [[UIAlertView alloc] initWithTitle:@"有来电" message:[NSString stringWithFormat:@"您有个新来电请接听%@",object[1]] delegate:self cancelButtonTitle:nil otherButtonTitles:@"拒接", @"接听", nil];
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

- (void)onReceiveHangUpCall:(NSNotification *)notification {
    //[[[UIAlertView alloc] initWithTitle:nil message:@"挂断" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];


  
    
    
}

- (void)onCallBtnClicked:(UIButton *)button {
    
    [[PJSua sharedInstance] setVideoCodec];
    [[PJSua sharedInstance] makeVideoCall:self.userTextField.text domain:self.hostTextField.text];
//    [[PJSua sharedInstance] makeAudioCall:self.userTextField.text domain:self.hostTextField.text];
    
}

- (void)onHangUpBtnClicked:(UIButton *)button {

    [[PJSua sharedInstance] hangUp:self.phoneID];
}


- (UIView *)vid_preview
{
    pj_thread_desc rtpdesc;
    pj_thread_t *thread = 0;
    
    if(!pj_thread_is_registered()) {
        if (pj_thread_register(NULL, rtpdesc, &thread) == PJ_SUCCESS) {
            
        }
    }
    
    
    pjmedia_vid_dev_index widx = PJMEDIA_VID_DEFAULT_CAPTURE_DEV;
    
    pjsua_vid_preview_param p;
    
    pjsua_vid_preview_param_default(&p);
    
    p.wnd_flags = PJMEDIA_VID_DEV_WND_BORDER| PJMEDIA_VID_DEV_WND_RESIZABLE;
    
    p.show = PJ_TRUE;
    p.format.det.vid.size.h = 0;
    p.format.det.vid.size.w = 0;
    
    pj_status_t status =  pjsua_vid_preview_start(widx, &p);
    if (!(status == PJ_SUCCESS)) {
        NSLog(@"pjsua_vid_preview_start 不成功");
    }
    
    
    
    pjsua_vid_win_id a = pjsua_vid_preview_get_win(widx);
    //2.6 调用这个方法会崩溃 不调用也可以
    //    pjsua_vid_win_set_show(a, PJ_TRUE);
    
    pjsua_vid_win_info wi;
    pjsua_vid_win_get_info(a, &wi);
    
    UIView *view = (__bridge UIView *)wi.hwnd.info.ios.window;

    return view;
}





- (void)displayVideo:(NSNotification *)notification {
    
    pjsua_vid_win_id wid = [[notification object] intValue];
    int i, last;
    
    i = (wid == PJSUA_INVALID_ID) ? 0 : wid;
    last = (wid == PJSUA_INVALID_ID) ? PJSUA_MAX_VID_WINS : wid+1;
    
    for (;i < last; ++i) {
        pjsua_vid_win_info wi;
        
//        pjsua_vid_win_set_size(<#pjsua_vid_win_id wid#>, <#const pjmedia_rect_size *size#>)
        //pjsua_codec_info *codecs;
        //unsigned int count = 0;
        //pjsua_vid_enum_codecs(codecs, &count);
        //NSLog(@"%d", count);
        //NSLog(@"%@", codecs);
        
//        pjsua_vid_win_rotate(wid, -90);
        
        if (pjsua_vid_win_get_info(i, &wi) == PJ_SUCCESS) {
            UIView *parent = self.view;
            UIView *view = (__bridge UIView *)wi.hwnd.info.ios.window;
            
            if (view) {
                /* Add the video window as subview */
                if (![view isDescendantOfView:parent])
                {
                     [parent addSubview:view];
                }
//
//                pjsua_vid_win_set_show(wid, PJ_TRUE);
                view.hidden = NO;
                
//                CGFloat viewW = 200;
//                if (isIphone4) {
//                    viewW = 150;
//                } else {
//                    viewW = 400;
//                }
                
                CGFloat viewM = 10;
//                CGFloat viewH = screenHeight - CGRectGetMaxY(self.hangUpBtn.frame) - tabBarHight - 2*viewM;
                 CGFloat viewH = screenWidth ;
                
                
                CGFloat viewW = screenWidth ;
                CGFloat viewY = CGRectGetMaxY(self.hangUpBtn.frame) + viewM;
                CGFloat viewX = screenWidth/2 - viewW/2;
                
                view.frame = CGRectMake(viewX, viewY, viewW, viewH);
                
//                 view.transform=CGAffineTransformMakeRotation (M_PI_2);
//           
                self.vid_preview.center=CGPointMake(58, 67);
//                self.vid_preview.transform=CGAffineTransformIdentity;
//            
//                self.vid_preview.transform = CGAffineTransformScale(self.vid_preview.transform, 0.4, 0.4);
                 self.vid_preview.transform = CGAffineTransformMakeScale(0.4, 0.4);
                
//                self.vid_preview.transform = CGAffineTransformRotate (self.vid_preview.transform, M_PI_2*3);
//              
                [view addSubview:self.vid_preview];
                
                
//                if (!wi.is_native) {
////                     Resize it to fit width
//                    view.bounds = CGRectMake(0, 0, parent.bounds.size.width,
//                                             (parent.bounds.size.height *
//                                              1.0*parent.bounds.size.width/
//                                              view.bounds.size.width));
//                    
//                    view.center = CGPointMake(parent.bounds.size.width/2.0,
//                                              view.bounds.size.height/2.0);
//                } else {
//                    /* Preview window, move it to the bottom */
//                    view.center = CGPointMake(parent.bounds.size.width/2.0,
//                                              parent.bounds.size.height-
//                                              view.bounds.size.height/2.0);
//                }
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [[PJSua sharedInstance] hangUp:self.phoneID];
    } else {
        // 因为接到视频电话后要回复，也会发起一个视频电话，这个电话的设置方向就是对方将要现实的方向
//      [[PJSua sharedInstance] setVideoCaptureOrientation:UIDeviceOrientationPortrait];
        [[PJSua sharedInstance] setVideoCodec];
        [[PJSua sharedInstance] answer:self.phoneID];
    }
}

// 消失键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.userTextField resignFirstResponder];
    [self.hostTextField resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
