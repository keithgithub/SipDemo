//
//  Constant.h
//  Voip
//
//  Created by A on 16/9/18.
//  Copyright © 2016年 A. All rights reserved.
//

#ifndef Constant_h
#define Constant_h

#define screenBounds        ([[UIScreen mainScreen] bounds])
#define screenSize          (screenBounds.size)

#define screenWidth         (screenSize.width)
#define screenHeight        (screenSize.height)

//#define screenWidth        MIN(screenSize.height, screenSize.width)
//#define screenHeight       MAX(screenSize.height, screenSize.width)


#define tabBarHight 49

// iPhone4 用于调试被呼叫方
#define isIphone4 YES
//#define isIphone4 (screenSize.width != 320)

#define isLocal NO

#endif /* Constant_h */
