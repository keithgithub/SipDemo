//
//  PJSua.h
//  Voip
//
//  Created by A on 16/9/18.
//  Copyright © 2016年 A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <pjsua.h>
#import <pjlib.h>
#import <pjmedia.h>

extern NSString *const PJSUARegisterResultNotification;
extern NSString *const PJSUAIncomingCallNotification;
extern NSString *const PJSUAHangUpCallNotification;
extern NSString *const PJSUAShowVideoNotification;

@interface PJSua : NSObject

+ (instancetype)sharedInstance;
- (void)registerToServer:(NSString *)domian username:(NSString *)username passwd:(NSString *)passwd;
- (void)unregister;
- (void)makeAudioCall:(NSString *)callname domain:(NSString *)domian;
- (void)makeVideoCall:(NSString *)callname domain:(NSString *)domian;

- (void)answer:(NSInteger)phoneID;
- (void)hangUp:(NSInteger)phoneID;

/*
 仅支持以下几种方向
 UIDeviceOrientationPortrait,
 UIDeviceOrientationPortraitUpsideDown,
 UIDeviceOrientationLandscapeLeft,
 UIDeviceOrientationLandscapeRight,
 */
- (void)setVideoCaptureOrientation:(UIDeviceOrientation )orientation;
- (pj_status_t)setVideoCodec;
@end
