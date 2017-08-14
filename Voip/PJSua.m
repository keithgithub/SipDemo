 //
//  PJSua.m
//  Voip
//
//  Created by A on 16/9/18.
//  Copyright © 2016年 A. All rights reserved.
//

#import "PJSua.h"
#import <UIKit/UIKit.h>

NSString *const PJSUARegisterResultNotification     =   @"PJSUARegisterResultNotification";
NSString *const PJSUAIncomingCallNotification       =   @"PJSUAIncomingCallNotification";
NSString *const PJSUAHangUpCallNotification         =   @"PJSUAHangUpCallNotification";
NSString *const PJSUAShowVideoNotification          =   @"PJSUAShowVideoNotification";
NSString *const PJSUACallIdNotification          =   @"PJSUACallIdNotification";

@interface PJSua ()
@property (nonatomic, assign) pjsua_acc_id acc_id;
@end

@implementation PJSua

+ (instancetype)sharedInstance {
    static PJSua *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PJSua alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        pj_status_t status = [self app_init];
        if (status != PJ_SUCCESS) {
            NSLog(@"app_init failed");
            return nil;
        }
    }
    return self;
}

#define THIS_FILE  "PJSua.m"

- (pj_status_t)app_init {
    pjsua_config	 ua_cfg;
    pjsua_logging_config log_cfg;
    pjsua_media_config   media_cfg;
    pj_status_t status;
    
    // Must create pjsua before anything else!
    status = pjsua_create();
    if (status != PJ_SUCCESS) {
        pjsua_perror(THIS_FILE, "Error initializing pjsua", status);
        return status;
    }
    
    // Initialize configs with default settings.
    pjsua_config_default(&ua_cfg);
    pjsua_logging_config_default(&log_cfg);
    pjsua_media_config_default(&media_cfg);
    
    // At the very least, application would want to override
    // the call callbacks in pjsua_config:
    ua_cfg.cb.on_incoming_call = on_incoming_call;
    ua_cfg.cb.on_call_state = on_call_state;
    ua_cfg.cb.on_call_media_state = on_call_media_state;
    ua_cfg.cb.on_reg_state2 = on_reg_state2;
    
    // Customize other settings (or initialize them from application specific
    // configuration file):
    
    
    // Initialize pjsua
    status = pjsua_init(&ua_cfg, &log_cfg, &media_cfg);
    if (status != PJ_SUCCESS) {
        pjsua_perror(THIS_FILE, "Error initializing pjsua", status);
        return status;
    }
    
    pjsua_transport_config cfg;
    pjsua_transport_config_default(&cfg);
    cfg.port = 0;
    status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, NULL);
    if (status != PJ_SUCCESS) {
        pjsua_perror(THIS_FILE, "Error creating transport", status);
        return status;
    }
    
    status = pjsua_start();
    if (status != PJ_SUCCESS) {
        pjsua_perror(THIS_FILE, "Error starting pjsua", status);
        return status;
    }
    
    return PJ_SUCCESS;
}


static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata)
{
    /*** 来电的回调函数 */
    pjsua_call_info ci;
    //@def PJ_UNUSED_ARG(arg)* @param参数参数名称。* PJ_UNUSED_ARG防止警告未使用的参数在一个函数中
    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);
    //获取呼叫信息
    pjsua_call_get_info(call_id, &ci);
    pjsua_call_get_info(call_id, &ci);
    
    //*写日志消息。*这是主要宏观用来写文本日志后端。** @param级别日志详细级别。更低的数字表明更高*重要性,级别0表示致命错误。只有*数字参数是允许的(如不变量)。* @param arg封闭“printf“像参数,与第一*参数是发送者,第二个参数是格式*字符串和以下参数变量的数量*参数适合的格式字符串。**样品:* \逐字PJ_LOG(2(__FILE__,“当前值% d值));\ endverbatim* @hideinitializer* /
    //(int)ci.remote_info.slen远程URL的长度
    //ci.remote_info.ptr缓冲区的指针,它是按照惯例不以空字符结尾
    PJ_LOG(3,(THIS_FILE, "Incoming call from %.*s!!",
              (int)ci.remote_info.slen,ci.remote_info.ptr));
    NSLog(@"---------%ld,%s",ci.remote_info.slen,ci.remote_info.ptr);
    // NSLog(@"-----------%d,%d, %d",call_id,acc_id,ci.id);
    
    char *phoneId = ci.remote_info.ptr;
    NSArray *arr = @[@(call_id),[NSString stringWithFormat:@"%s",phoneId]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotification *notify =[NSNotification notificationWithName:PJSUAIncomingCallNotification object:arr];
        [[NSNotificationCenter defaultCenter] postNotification:notify];
    });
}

static void on_incoming_call_bak(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata)
{
    pjsua_call_info call_info;
    
    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);
    
    pjsua_call_get_info(call_id, &call_info);
    
    pjsua_call_id current_call = PJSUA_INVALID_ID;
    if (current_call==PJSUA_INVALID_ID)
        current_call = call_id;
    
#ifdef USE_GUI
    if (!showNotification(call_id))
        return;
#endif
    
    /* Start ringback */
    ring_start(call_id);

//    if (app_config.auto_answer > 0) {
//        pjsua_call_setting opt;
//        
//        pjsua_call_setting_default(&opt);
//        opt.aud_cnt = app_config.aud_cnt;
//        opt.vid_cnt = app_config.vid.vid_cnt;
//        
//        pjsua_call_answer2(call_id, &opt, app_config.auto_answer, NULL,
//                           NULL);
//    }
//    
//    if (app_config.auto_answer < 200) {
//        char notif_st[80] = {0};
//        
//#if PJSUA_HAS_VIDEO
//        if (call_info.rem_offerer && call_info.rem_vid_cnt) {
//            snprintf(notif_st, sizeof(notif_st),
//                     "To %s the video, type \"vid %s\" first, "
//                     "before answering the call!\n",
//                     (app_config.vid.vid_cnt? "reject":"accept"),
//                     (app_config.vid.vid_cnt? "disable":"enable"));
//        }
//#endif
//        
//        PJ_LOG(3,(THIS_FILE,
//                  "Incoming call for account %d!\n"
//                  "Media count: %d audio & %d video\n"
//                  "%s"
//                  "From: %s\n"
//                  "To: %s\n"
//                  "Press %s to answer or %s to reject call",
//                  acc_id,
//                  call_info.rem_aud_cnt,
//                  call_info.rem_vid_cnt,
//                  notif_st,
//                  call_info.remote_info.ptr,
//                  call_info.local_info.ptr,
//                  (app_config.use_cli?"ca a":"a"),
//                  (app_config.use_cli?"g":"h")));
//    }
}

/* Callback called by the library when call's state has changed */
static void on_call_state(pjsua_call_id call_id, pjsip_event *e) {
    /***  呼叫状态改变的回调函数 */
    pjsua_call_info ci;
    
    PJ_UNUSED_ARG(e);
    
    pjsua_call_get_info(call_id, &ci);
    PJ_LOG(3,(THIS_FILE, "Call %d state=%.*s", call_id,
              (int)ci.state_text.slen,ci.state_text.ptr));
  
    
    if (!strcmp(ci.state_text.ptr, "DISCONNCTD"))
    {
        // 通话已经结束  无论是对方挂断还是我自己挂断都进入这个方法
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
            NSNotification *notify = [NSNotification notificationWithName:PJSUAHangUpCallNotification object:nil];
            [center postNotification:notify];
        });
    }
    
   //自己修改的方法
    
//    pjsua_call_info ci;
//    pjsua_call_get_info(call_id, &ci);
//    
//    id argument = @{
//                    @"call_id"  : @(call_id),
//                    @"state"    : @(ci.state)
//                    };
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"SIPCallStatusChangedNotification" object:nil userInfo:argument];
//    });
//
//    
    
    
    
    
    
}


/* Callback called by the library when call's media state has changed 回调由库调用时调用的媒体状态发生了变化*/
static void on_call_media_state_bak(pjsua_call_id call_id) {
    //rem_vid_cnt视频流，rem_aud_cnt音频流， 结构体pj_time_val total_duration。总电话持续时间,包括安装时间 秒时间ci.total_duration.sec
    //connect_duration最新的调用连接持续时间(0时调用*建立
    //ci里头有个数组多连接
    //这个结构描述信息和当前状态的一个电话。
    //来电回调函数
    pjsua_call_info ci;
    
    //获取细节信息指定的电话。** @param call_id调用识别。* @param信息调用信息初始化。** @return pj_success成功,或适当的错误代码
    
    pjsua_call_get_info(call_id, &ci);
    //活跃的
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE)
    {
        // When media is active, connect call to sound device.
        //建立单向媒体流从源到汇。一个源*可能传送到多个目的地/下沉。如果多个*来源传送相同的水槽,媒体将混合*在一起。源和汇可以引用相同的ID,有效*循环媒体。**如果双向媒体流,应用程序需要调用*这个函数两次,第二个参数*逆转。** @param源媒体/发射机的源端口ID。* @param水槽端口目的地媒体/收到的ID。** @return pj_success成功,或适当的错误代码
        //pjsua_conf_port_id	conf_slot会议第一音频流的端口号
        //pjmedia_dir		media_dir 第一音频流媒体的方向
        pjsua_conf_connect(ci.conf_slot, 0);
        pjsua_conf_connect(0, ci.conf_slot);
        
    }
}

/*
 * Callback on media state changed event.
 * The action may connect the call to sound device, to file, or
 * to loop the call.
 */
static void on_call_media_state(pjsua_call_id call_id)
{
    pjsua_call_info call_info;
    unsigned mi;
    pj_bool_t has_error = PJ_FALSE;
    
    pjsua_call_get_info(call_id, &call_info);
    
    for (mi=0; mi<call_info.media_cnt; ++mi) {
        on_call_generic_media_state(&call_info, mi, &has_error);
        
        switch (call_info.media[mi].type) {
            case PJMEDIA_TYPE_AUDIO:
                on_call_audio_state(&call_info, mi, &has_error);
                break;
            case PJMEDIA_TYPE_VIDEO:
                on_call_video_state(&call_info, mi, &has_error);
                break;
            default:
                /* Make gcc happy about enum not handled by switch/case */
                break;
        }
    }
    
    if (has_error) {
        pj_str_t reason = pj_str("Media failed");
        pjsua_call_hangup(call_id, 500, &reason, NULL);
    }
    
#if PJSUA_HAS_VIDEO
    /* Check if remote has just tried to enable video */
    if (call_info.rem_offerer && call_info.rem_vid_cnt)
    {
        int vid_idx;
        
        /* Check if there is active video */
        vid_idx = pjsua_call_get_vid_stream_idx(call_id);
        if (vid_idx == -1 || call_info.media[vid_idx].dir == PJMEDIA_DIR_NONE) {
            PJ_LOG(3,(THIS_FILE,
                      "Just rejected incoming video offer on call %d, "
                      "use \"vid call enable %d\" or \"vid call add\" to "
                      "enable video!", call_id, vid_idx));
        }
    }
#endif
}

/* General processing for media state. "mi" is the media index */
static void on_call_generic_media_state(pjsua_call_info *ci, unsigned mi,
                                        pj_bool_t *has_error)
{
    const char *status_name[] = {
        "None",
        "Active",
        "Local hold",
        "Remote hold",
        "Error"
    };
    
    PJ_UNUSED_ARG(has_error);
    
    pj_assert(ci->media[mi].status <= PJ_ARRAY_SIZE(status_name));
    pj_assert(PJSUA_CALL_MEDIA_ERROR == 4);
    
    PJ_LOG(4,(THIS_FILE, "Call %d media %d [type=%s], status is %s",
              ci->id, mi, pjmedia_type_name(ci->media[mi].type),
              status_name[ci->media[mi].status]));
}

/* Process audio media state. "mi" is the media index. */
static void on_call_audio_state(pjsua_call_info *ci, unsigned mi,
                                pj_bool_t *has_error)
{
    PJ_UNUSED_ARG(has_error);
    
    /* Stop ringback */
    ring_stop(ci->id);
    
    /* Connect ports appropriately when media status is ACTIVE or REMOTE HOLD,
     * otherwise we should NOT connect the ports.
     */
    if (ci->media[mi].status == PJSUA_CALL_MEDIA_ACTIVE ||
        ci->media[mi].status == PJSUA_CALL_MEDIA_REMOTE_HOLD)
    {
//        pj_bool_t connect_sound = PJ_TRUE;
//        pj_bool_t disconnect_mic = PJ_FALSE;
//        pjsua_conf_port_id call_conf_slot;
//        
//        call_conf_slot = ci->media[mi].stream.aud.conf_slot;
//        
//        /* Loopback sound, if desired */
//        if (app_config.auto_loop) {
//            pjsua_conf_connect(call_conf_slot, call_conf_slot);
//            connect_sound = PJ_FALSE;
//        }
//        
//        /* Automatically record conversation, if desired */
//        if (app_config.auto_rec && app_config.rec_port != PJSUA_INVALID_ID) {
//            pjsua_conf_connect(call_conf_slot, app_config.rec_port);
//        }
//        
//        /* Stream a file, if desired */
//        if ((app_config.auto_play || app_config.auto_play_hangup) &&
//            app_config.wav_port != PJSUA_INVALID_ID)
//        {
//            pjsua_conf_connect(app_config.wav_port, call_conf_slot);
//            connect_sound = PJ_FALSE;
//        }
//        
//        /* Stream AVI, if desired */
//        if (app_config.avi_auto_play &&
//            app_config.avi_def_idx != PJSUA_INVALID_ID &&
//            app_config.avi[app_config.avi_def_idx].slot != PJSUA_INVALID_ID)
//        {
//            pjsua_conf_connect(app_config.avi[app_config.avi_def_idx].slot,
//                               call_conf_slot);
//            disconnect_mic = PJ_TRUE;
//        }
//        
//        /* Put call in conference with other calls, if desired */
//        if (app_config.auto_conf) {
//            pjsua_call_id call_ids[PJSUA_MAX_CALLS];
//            unsigned call_cnt=PJ_ARRAY_SIZE(call_ids);
//            unsigned i;
//            
//            /* Get all calls, and establish media connection between
//             * this call and other calls.
//             */
//            pjsua_enum_calls(call_ids, &call_cnt);
//            
//            for (i=0; i<call_cnt; ++i) {
//                if (call_ids[i] == ci->id)
//                    continue;
//                
//                if (!pjsua_call_has_media(call_ids[i]))
//                    continue;
//                
//                pjsua_conf_connect(call_conf_slot,
//                                   pjsua_call_get_conf_port(call_ids[i]));
//                pjsua_conf_connect(pjsua_call_get_conf_port(call_ids[i]),
//                                   call_conf_slot);
//                
//                /* Automatically record conversation, if desired */
//                if (app_config.auto_rec && app_config.rec_port !=
//                    PJSUA_INVALID_ID)
//                {
//                    pjsua_conf_connect(pjsua_call_get_conf_port(call_ids[i]),
//                                       app_config.rec_port);
//                }
//                
//            }
//            
//            /* Also connect call to local sound device */
//            connect_sound = PJ_TRUE;
//        }
//        
//        /* Otherwise connect to sound device */
//        if (connect_sound) {
//            pjsua_conf_connect(call_conf_slot, 0);
//            if (!disconnect_mic)
//                pjsua_conf_connect(0, call_conf_slot);
//            
//            /* Automatically record conversation, if desired */
//            if (app_config.auto_rec && app_config.rec_port != PJSUA_INVALID_ID)
//            {
//                pjsua_conf_connect(call_conf_slot, app_config.rec_port);
//                pjsua_conf_connect(0, app_config.rec_port);
//            }
//        }
        
        //获取细节信息指定的电话。** @param call_id调用识别。* @param信息调用信息初始化。** @return pj_success成功,或适当的错误代码
        
        pjsua_conf_connect(ci->conf_slot, 0);
        pjsua_conf_connect(0, ci->conf_slot);
    }
}

/* Process video media state. "mi" is the media index. */
static void on_call_video_state(pjsua_call_info *ci, unsigned mi,
                                pj_bool_t *has_error)
{
    if (ci->media_status != PJSUA_CALL_MEDIA_ACTIVE)
        return;
    
    arrange_window(ci->media[mi].stream.vid.win_in);
    
//    NSLog(@"ci->media[mi].stream.vid.win_in: %d", ci->media[mi].stream.vid.win_in);
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
//        [notiCenter postNotificationName:PJSUAShowVideoNotification object:@(ci->media[mi].stream.vid.win_in)];
//    });
}

void arrange_window(pjsua_vid_win_id wid)
{
    pjmedia_coord pos;
    int i, last;
    
    pos.x = 0;
    pos.y = 10;
    last = (wid == PJSUA_INVALID_ID) ? PJSUA_MAX_VID_WINS : wid;
    
    for (i=0; i<last; ++i) {
        pjsua_vid_win_info wi;
        pj_status_t status;
        
        status = pjsua_vid_win_get_info(i, &wi);
        if (status != PJ_SUCCESS)
            continue;
        
        if (wid == PJSUA_INVALID_ID)
            pjsua_vid_win_set_pos(i, &pos);
        
        if (wi.show)
            pos.y += wi.size.h;
    }
    
    if (wid != PJSUA_INVALID_ID)
        pjsua_vid_win_set_pos(wid, &pos);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
        [notiCenter postNotificationName:PJSUAShowVideoNotification object:@(wid)];
    });
    
}

static void on_reg_state2(pjsua_acc_id acc_id, pjsua_reg_info *info) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
        if (info->cbparam->code == 200) {
            [notiCenter postNotificationName:PJSUARegisterResultNotification object:@YES];
            pjsua_acc_set_online_status(acc_id, PJ_TRUE); // TODO: 记得验证
        } if (info->cbparam->code == 403) {
            [notiCenter postNotificationName:PJSUARegisterResultNotification object:@NO];
        }
    });
}

static void ring_stop(pjsua_call_id call_id)
{
//    if (app_config.no_tones)
//        return;
    
//    if (app_config.call_data[call_id].ringback_on) {
//        app_config.call_data[call_id].ringback_on = PJ_FALSE;
    
//        pj_assert(app_config.ringback_cnt>0);
//        if (--app_config.ringback_cnt == 0 &&
//            app_config.ringback_slot!=PJSUA_INVALID_ID)
//        {
//            pjsua_conf_disconnect(app_config.ringback_slot, 0);
//            pjmedia_tonegen_rewind(app_config.ringback_port);
//        }
////    }
//    
////    if (app_config.call_data[call_id].ring_on) {
////        app_config.call_data[call_id].ring_on = PJ_FALSE;
//    
//        pj_assert(app_config.ring_cnt>0);
//        if (--app_config.ring_cnt == 0 &&
//            app_config.ring_slot!=PJSUA_INVALID_ID)
//        {
//            pjsua_conf_disconnect(app_config.ring_slot, 0);
//            pjmedia_tonegen_rewind(app_config.ring_port);
//        }
//    }
}

static void ring_start(pjsua_call_id call_id)
{
//    if (app_config.no_tones)
//        return;
//    
//    if (app_config.call_data[call_id].ring_on)
//        return;
//    
//    app_config.call_data[call_id].ring_on = PJ_TRUE;
//    
//    if (++app_config.ring_cnt==1 &&
//        app_config.ring_slot!=PJSUA_INVALID_ID)
//    {
//        pjsua_conf_connect(app_config.ring_slot, 0);
//    }
}

- (void)registerToServer:(NSString *)domian username:(NSString *)username passwd:(NSString *)passwd {
    
    NSString *ID = [NSString stringWithFormat:@"sip:%@@%@",username,domian];
    NSString *reg_uri = [NSString stringWithFormat:@"sip:%@",domian];
    
    pjsua_acc_config cfg;
    pjsua_acc_config_default(&cfg);
    cfg.id = pj_str((char *)[ID UTF8String]);
    cfg.reg_uri = pj_str((char *)[reg_uri UTF8String]);
    cfg.reg_retry_interval = 0; // 不让重试
    cfg.cred_count = 1;
    //cfg.cred_info[0]数组的凭证。如果需要注册,通常应该*至少一个指定的凭据,成功进行身份验证*对服务提供者。更多的证书可以指定,*示例请求时将受到的挑战*代理的路线
    cfg.cred_info[0].realm = pj_str("*");//验证
    cfg.cred_info[0].scheme = pj_str("digest");//计划(如。“消化”)
    cfg.cred_info[0].username = pj_str((char *)[username UTF8String]);//用户名
    cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;//密码数据的类型
    cfg.cred_info[0].data = pj_str((char *)[passwd UTF8String]);//密码
    cfg.vid_in_auto_show = PJ_TRUE;
    cfg.vid_out_auto_transmit = PJ_TRUE;
    
    pj_status_t status = pjsua_acc_add(&cfg, PJ_TRUE, &_acc_id);
    NSLog(@"_acc_id %d", _acc_id);
    if (status != PJ_SUCCESS) {
        pjsua_perror(THIS_FILE, "Error adding account", status);
        return;
    }
}

- (void)unregister {
    
    pjsua_acc_del(_acc_id);
}

- (void)destory {
    
}

- (void)makeAudioCall:(NSString *)callname domain:(NSString *)domian {
    NSString *ID = [NSString stringWithFormat:@"sip:%@@%@",callname,domian];
    
    pj_status_t status;
    
    char *curl = (char *)[ID UTF8String];
    
    status = pjsua_verify_sip_url(curl);
    
    if (status != PJ_SUCCESS) {
        pjsua_perror(THIS_FILE, "Error url", status);
        return;
    }
    
//    pjsua_call_id current_call = PJSUA_INVALID_ID;
    
    pjsua_call_setting setting;
    pjsua_call_setting_default(&setting);
    setting.vid_cnt = 0;
    
    pj_str_t url = pj_str(curl);
    
    pjsua_call_make_call(_acc_id, &url, &setting, NULL, NULL, NULL);
    
//    pjsua_acc_id acct_id = (pjsua_acc_id)[[NSUserDefaults standardUserDefaults] integerForKey:@"login_account_id"];
//    NSString *ID = [NSString stringWithFormat:@"sip:%@@%@",callname,domian];
//    
//    pj_status_t status;
//    pj_str_t dest_uri = pj_str((char *)ID.UTF8String);
//    
//    status = pjsua_call_make_call(acct_id, &dest_uri, 0, NULL, NULL, &_acc_id);
//    
//    if (status != PJ_SUCCESS) {
//        char  errMessage[PJ_ERR_MSG_SIZE];
//        pj_strerror(status, errMessage, sizeof(errMessage));
//        NSLog(@"外拨错误, 错误信息:%d(%s) !", status, errMessage);
//    }
    
    

    
    
}

- (void)makeVideoCall:(NSString *)callname domain:(NSString *)domian {
//    struct input_result result;
//    char dest[64] = {0};
//    char out_str[128];
//    pj_str_t tmp = pj_str(dest);
//    
//    pj_strncpy_with_null(&tmp, &cval->argv[1], sizeof(dest));
//    
//    pj_ansi_snprintf(out_str,
//                     sizeof(out_str),
//                     "(You currently have %d calls)\n",
//                     pjsua_call_get_count());
//    
//    pj_cli_sess_write_msg(cval->sess, out_str, pj_ansi_strlen(out_str));
//    
//     input destination. 
//    get_input_url(tmp.ptr, tmp.slen, cval, &result);
//    if (result.nb_result != PJSUA_APP_NO_NB) {
//        pjsua_buddy_info binfo;
//        if (result.nb_result == -1 || result.nb_result == 0) {
//            static const pj_str_t err_msg =
//            {"You can't do that with make call!\n", 35};
//            pj_cli_sess_write_msg(cval->sess, err_msg.ptr, err_msg.slen);
//            return;
//        }
//        pjsua_buddy_get_info(result.nb_result-1, &binfo);
//        pj_strncpy(&tmp, &binfo.uri, sizeof(dest));
//    } else if (result.uri_result) {
//        tmp = pj_str(result.uri_result);
//    } else {
//        tmp.slen = 0;
//    }
//    
//    pjsua_msg_data_init(&msg_data);
//    TEST_MULTIPART(&msg_data);
//    
    
    
    pj_status_t status;
    NSString *ID = [NSString stringWithFormat:@"sip:%@@%@", callname, domian];
    char *curl = (char *)[ID UTF8String];
    pj_str_t url = pj_str(curl);
    status = pjsua_verify_sip_url(curl);
    if (status != PJ_SUCCESS) {
        pjsua_perror(THIS_FILE, "Error url", status);
        return;
    }
    
    pjsua_call_setting call_opt;
    pjsua_call_setting_default(&call_opt);
    call_opt.aud_cnt = 1;
    call_opt.vid_cnt = 1;
    call_opt.flag = 4;
    
    pjsua_msg_data msg_data;
    pjsua_msg_data_init(&msg_data);
    //TEST_MULTIPART(&msg_data);
    
    pjsua_call_id current_call = PJSUA_INVALID_ID;
    
    pjsua_call_make_call(pjsua_acc_get_default(), &url, &call_opt, NULL,
                         &msg_data, &current_call);
    
}

void app_config_init_video2(pjsua_acc_config *acc_cfg)
{
//    acc_cfg->vid_in_auto_show = app_config.vid.in_auto_show;
//    acc_cfg->vid_out_auto_transmit = app_config.vid.out_auto_transmit;
//    /* Note that normally GUI application will prefer a borderless
//     * window.
//     */
//    acc_cfg->vid_wnd_flags = PJMEDIA_VID_DEV_WND_BORDER |
//    PJMEDIA_VID_DEV_WND_RESIZABLE;
//    acc_cfg->vid_cap_dev = app_config.vid.vcapture_dev;
//    acc_cfg->vid_rend_dev = app_config.vid.vrender_dev;
//    
//    if (app_config.avi_auto_play &&
//        app_config.avi_def_idx != PJSUA_INVALID_ID &&
//        app_config.avi[app_config.avi_def_idx].dev_id != PJMEDIA_VID_INVALID_DEV)
//    {
//        acc_cfg->vid_cap_dev = app_config.avi[app_config.avi_def_idx].dev_id;
//    }
}

- (void)answer:(NSInteger)phoneID {
    pjsua_call_answer((int)phoneID, 200, NULL, NULL); // 接来电
}

- (void)hangUp:(NSInteger)phoneID {
//    pjsua_call_hangup((int)phoneID, 200, NULL, NULL);
    pjsua_call_hangup_all();
}

- (void)setVideoCaptureOrientation:(UIDeviceOrientation )orientation {
    
//    const pjmedia_orient pj_ori[5] =
//    {
//        PJMEDIA_ORIENT_UNKNOWN,
//        PJMEDIA_ORIENT_NATURAL,
//        PJMEDIA_ORIENT_ROTATE_90DEG,  /* UIDeviceOrientationPortrait */
//        PJMEDIA_ORIENT_ROTATE_270DEG, /* UIDeviceOrientationPortraitUpsideDown */
//        PJMEDIA_ORIENT_ROTATE_180DEG, /* UIDeviceOrientationLandscapeLeft,
//                                       home button on the right side */
//                                        /* UIDeviceOrientationLandscapeRight,
//                                       home button on the left side */
//    };
//    
//    
////    const pjmedia_orient pj_ori[4] =
////    {
////        PJMEDIA_ORIENT_ROTATE_90DEG,  /* UIDeviceOrientationPortrait */
////        PJMEDIA_ORIENT_ROTATE_270DEG, /* UIDeviceOrientationPortraitUpsideDown */
////        PJMEDIA_ORIENT_ROTATE_180DEG, /* UIDeviceOrientationLandscapeLeft,
////                                       home button on the right side */
////        PJMEDIA_ORIENT_NATURAL        /* UIDeviceOrientationLandscapeRight,
////                                       home button on the left side */
////    };
//
//    
//    
//    
//    int dev_orientation = 0;
//    switch (orientation) {
//        case UIDeviceOrientationPortrait:
//            dev_orientation = 1;
//            break;
//        
//        case UIDeviceOrientationPortraitUpsideDown:
//            dev_orientation = 2;
//            break;
//            
//        case UIDeviceOrientationLandscapeLeft:
//            dev_orientation = 3;
//            break;
//            
//        case UIDeviceOrientationLandscapeRight:
//            dev_orientation = 4;
//            break;
//
//        default:
//            break;
//    }
//    
////    for (int i = pjsua_vid_dev_count()-1; i >= 0; i--) {
//        pjsua_vid_dev_set_setting(0,  PJMEDIA_VID_DEV_CAP_ORIENTATION,
//                                  &pj_ori[dev_orientation], PJ_TRUE);
////    }

    
    
    const pjmedia_orient pj_ori[4] =
    {
        PJMEDIA_ORIENT_ROTATE_90DEG,  /* UIDeviceOrientationPortrait */
        PJMEDIA_ORIENT_ROTATE_270DEG, /* UIDeviceOrientationPortraitUpsideDown */
        PJMEDIA_ORIENT_ROTATE_180DEG, /* UIDeviceOrientationLandscapeLeft,
                                       home button on the right side */
        PJMEDIA_ORIENT_NATURAL        /* UIDeviceOrientationLandscapeRight,
                                       home button on the left side */
    };
    static pj_thread_desc a_thread_desc;
    static pj_thread_t *a_thread;
    static UIDeviceOrientation prev_ori = 0;
    UIDeviceOrientation dev_ori = [[UIDevice currentDevice] orientation];
    
    if (dev_ori == prev_ori) return;
    
    NSLog(@"Device orientation changed: %ld", (long)(prev_ori = dev_ori));
    
    if (dev_ori >= UIDeviceOrientationPortrait &&
        dev_ori <= UIDeviceOrientationLandscapeRight)
    {
        if (!pj_thread_is_registered()) {
            pj_thread_register("ipjsua", a_thread_desc, &a_thread);
        }
        
        pjsua_vid_dev_set_setting(PJMEDIA_VID_DEFAULT_CAPTURE_DEV,
                                  PJMEDIA_VID_DEV_CAP_ORIENTATION,
                                  &pj_ori[dev_ori-1], PJ_TRUE);
        
    }
    
    
    
    
    
    
}

// 视频设置
//- (pj_status_t)cmd_set_vid_codec_prio(pj_cli_cmd_val *cval) {
//    int prio = pj_strtol(&cval->argv[2]);
//    pj_status_t status;
//    
//    status = pjsua_vid_codec_set_priority(&cval->argv[1], (pj_uint8_t)prio);
//    if (status != PJ_SUCCESS)
//        PJ_PERROR(1,(THIS_FILE, status, "Set codec priority error"));
//    
//    return PJ_SUCCESS;
//}

- (pj_status_t)setVideoCodec {
    
    pj_status_t status;
    const pj_str_t codec_id = {"H264", 4}; //H264/97
    pjmedia_vid_codec_param cp;
    status = pjsua_vid_codec_get_param(&codec_id, &cp);
    if (status == PJ_SUCCESS) {
        // fps
        cp.enc_fmt.det.vid.fps.num = 10;
        cp.enc_fmt.det.vid.fps.denum = 1;
        
        // size
//        cp.enc_fmt.det.vid.size.w = 1280;
//        cp.enc_fmt.det.vid.size.h = 720;
//        
//        cp.enc_fmt.det.vid.size.w = 480;
//        cp.enc_fmt.det.vid.size.h = 640;
        
//        cp.enc_fmt.det.vid.size.w = 960;
//        cp.enc_fmt.det.vid.size.h = 960;
        
//        cp.enc_fmt.det.vid.size.w = 176;
//        cp.enc_fmt.det.vid.size.h = 144;
        
//        cp.enc_fmt.det.vid.size.w = 240;
//        cp.enc_fmt.det.vid.size.h = 320;

        cp.enc_fmt.det.vid.size.w = 375;
        cp.enc_fmt.det.vid.size.h = 375;
        
        // Bitrate
//        cp.enc_fmt.det.vid.avg_bps = 512000;
//        cp.enc_fmt.det.vid.max_bps = 1024000;

//        cp.enc_fmt.det.vid.avg_bps = 256000;
//        cp.enc_fmt.det.vid.max_bps = 512000;

//        cp.enc_fmt.det.vid.avg_bps = 128000;
//        cp.enc_fmt.det.vid.max_bps = 256000;
        
        cp.enc_fmt.det.vid.avg_bps = 128000/2;
        cp.enc_fmt.det.vid.max_bps = 256000;
        
        status = pjsua_vid_codec_set_param(&codec_id, &cp);
    }
    if (status != PJ_SUCCESS)
        PJ_PERROR(1,(THIS_FILE, status, "Set codec framerate error"));
    
    return PJ_SUCCESS;
}

//- (pj_status_t)cmd_set_vid_codec_bitrate(char *cval) {
//    pjmedia_vid_codec_param cp;
//    int M, N;
//    pj_status_t status;
//    
////    M = pj_strtol(&cval->argv[2]);
////    N = pj_strtol(&cval->argv[3]);
////    status = pjsua_vid_codec_get_param(&cval->argv[1], &cp);
////    if (status == PJ_SUCCESS) {
////        cp.enc_fmt.det.vid.avg_bps = M * 1000;
////        cp.enc_fmt.det.vid.max_bps = N * 1000;
////        status = pjsua_vid_codec_set_param(&cval->argv[1], &cp);
////    }
//    if (status != PJ_SUCCESS)
//        PJ_PERROR(1,(THIS_FILE, status, "Set codec bitrate error"));
//    
//    return status;
//}
//
//- (pj_status_t)cmd_set_vid_codec_size(char *cval) {
//    pjmedia_vid_codec_param cp;
//    int M, N;
//    pj_status_t status;
//    
////    M = pj_strtol(&cval->argv[2]);
////    N = pj_strtol(&cval->argv[3]);
////    status = pjsua_vid_codec_get_param(&cval->argv[1], &cp);
////    if (status == PJ_SUCCESS) {
////        cp.enc_fmt.det.vid.size.w = M;
////        cp.enc_fmt.det.vid.size.h = N;
////        status = pjsua_vid_codec_set_param(&cval->argv[1], &cp);
////    }
//    if (status != PJ_SUCCESS)
//        PJ_PERROR(1,(THIS_FILE, status, "Set codec size error"));
//    
//    return status;
//}

static void get_video_codec_id() {
    
    pjsua_codec_info ci[32];
    unsigned i, count = PJ_ARRAY_SIZE(ci);
    char codec_id[64];
    char desc[128];

    pjsua_vid_enum_codecs(ci, &count);
    for (i=0; i<count; ++i) {
        pjmedia_vid_codec_param cp;
        pjmedia_video_format_detail *vfd;
        pj_status_t status = PJ_SUCCESS;
        
        status = pjsua_vid_codec_get_param(&ci[i].codec_id, &cp);
        if (status != PJ_SUCCESS)
            continue;
        
        vfd = pjmedia_format_get_video_format_detail(&cp.enc_fmt, PJ_TRUE);
        
        pj_ansi_snprintf(codec_id, sizeof(codec_id),
                         "%.*s", (int)ci[i].codec_id.slen,
                         ci[i].codec_id.ptr);
        
        printf("****%s\n", codec_id);
        
//        pj_strdup2(param->pool, &param->choice[param->cnt].value, codec_id);
//        
//        pj_ansi_snprintf(desc, sizeof(desc),
//                         "Video, p[%d], f[%.2f], b[%d/%d], s[%dx%d]",
//                         ci[i].priority,
//                         (vfd->fps.num*1.0/vfd->fps.denum),
//                         vfd->avg_bps/1000, vfd->max_bps/1000,
//                         vfd->size.w, vfd->size.h);
//        
//        pj_strdup2(param->pool, &param->choice[param->cnt].desc, desc);
//        if (++param->cnt >= param->max_cnt)
//            break;
    }
}

@end
