//
//  kfxLogging.h
//  SampleLogging
//
//  Created by Kofax on 12/7/16.
//  Copyright © 2016 Kofax. All rights reserved.
//


#define KMDLogMessage(flag,s) [[KMDLogging sharedInstance]logMessageOfType:flag withMessage:[NSString stringWithFormat:@"%s : %@ : %@",__PRETTY_FUNCTION__,[NSThread currentThread],s]]

/*
 Each log are indicated by these flags . They will be used together with levels to filter out logs.
 */

typedef NS_OPTIONS(NSUInteger, LogFlag){
    
    // 0...00001 LogFlagError
    //For example : Server response  couldn't be parsed.
    
    LogFlag_Error      = (1 << 0),
    
    // 0...00010 LogFlagWarning
    //For example : Please select atleast one image to proceed further.
    
    LogFlag_Warning    = (1 << 1),
    
    // 0...00100 LogFlagInfo
    // For example : Notification of reachability changed .
    
    LogFlag_Info       = (1 << 2),
    
    // 0...01000 LogFlagDebug
    // For example : Current state of objects when error has occured .
    LogFlag_Debug      = (1 << 3),
    
};

/*
 Log levels are used to filter out logs. Used together with flags.
 */
typedef NS_ENUM(NSUInteger, LogLevel){
    
    // No logs
    
    LogLevel_Off       = 0,
    
    //Error logs only
    
    LogLevel_Error   = (LogFlag_Error),
    
    // Error and warning logs
    
    LogLevel_Warning   = (LogLevel_Error   | LogFlag_Warning),
    
    // Error, warning and info logs
    
    LogLevel_Info      = (LogLevel_Warning | LogFlag_Info),
    
    // Error, warning, info and debug logs
    
    LogLevel_Debug     = (LogLevel_Info    | LogFlag_Debug),
    
};

@interface KMDLogging : NSObject

@property (nonatomic,assign) LogLevel logLevel;
@property (nonatomic,assign) NSInteger thresholdInBytes; // It's the threshold when reached , we save the logs in file automatically  .


+ (instancetype)sharedInstance;

-(void)flushLogFiles;

-(void)writeLogstoFile;

-(void)logMessageOfType:(LogFlag)logFlag withMessage:(NSString *)strLogMessage;

- (instancetype)init NS_UNAVAILABLE;

+ (id)allocWithZone:(NSZone *)zone NS_UNAVAILABLE;

- (id)copyWithZone:(NSZone *)zone NS_UNAVAILABLE;



@end
