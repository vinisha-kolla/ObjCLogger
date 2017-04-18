//
//  kfxLogging.m
//  SampleLogging
//
//  Created by Kofax on 12/7/16.
//  Copyright © 2016 Kofax. All rights reserved.
//

#import "KMDLogging.h"
#import <sys/utsname.h>


#define DirectoryNameForSavingLogs @"LogFiles"

static KMDLogging * sharedInstance = nil;

@interface KMDLogging ()

@property (nonatomic) NSMutableString * strLogMessages; // Buffer to save Logs till the threshold is reached
@property (nonatomic) NSString *currentFileName; // File is created for an application's session

@end

@implementation KMDLogging

+ (instancetype)sharedInstance {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[self alloc] init];
        sharedInstance.logLevel = LogLevel_Info ;
        sharedInstance.thresholdInBytes = 0 ;
        
        [sharedInstance createDirectoryWithName:DirectoryNameForSavingLogs];
        sharedInstance.currentFileName = [sharedInstance createNewLogFileName];
        [sharedInstance createNewFileWithName:sharedInstance.currentFileName withHeaderMessage:[sharedInstance getTheHeaderMessageForFile]];
        sharedInstance.strLogMessages = [[NSMutableString alloc]init];
        
    });
    
    return sharedInstance;
}

-(void)dealloc {
    
}


#pragma mark - Log Related

-(void)logMessageOfType:(LogFlag)logFlag withMessage:(NSString *)strLogMessage {
    
    if (self.logLevel > 0 && (NSInteger)logFlag < self.logLevel)
    {
        NSString *strEmojiMessage = [self addingEmojiToLogMessage:strLogMessage withLogType:logFlag];
        NSLog(@"%@ ",strEmojiMessage);
        if (self.thresholdInBytes > 0) {
            
            [self bufferLogs:strLogMessage withLogType:logFlag];
        }
    }
}

- (void)bufferLogs:(NSString *)strLog withLogType:(LogFlag)logFlag  {
    
    NSString *strDateTime = [self convertTheDateToString:[NSDate date] withFormatter:[self logFileDateFormatter]];
    NSString *strLogWithNewLine = [[NSString alloc]initWithFormat:@"<br> %@ : %@",strDateTime,strLog];
    NSString *strHTMLLog = [self formattingToHTMLLog:strLogWithNewLine withLogType:logFlag];
    [self.strLogMessages appendString:strHTMLLog];
    
    // Check if threshold has been reached
    
    if([self hasThresholdReached:self.strLogMessages withThreshold:self.thresholdInBytes] == YES){
        
        [self writeLogstoFile];
    }

}

-(void)flushBuffer {
 
    [self.strLogMessages setString:@""];
}

#pragma mark - Public - File Related Operations


-(void)writeLogstoFile {
    
    NSString * strFilePath = [self getTheCurrentFilePathForLogs:self.currentFileName];
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForWritingAtPath:strFilePath];
    [fileHandler seekToEndOfFile];
    [fileHandler writeData:[self.strLogMessages dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self flushBuffer];
    
}
-(void)flushLogFiles {
    
    NSString *strDirectoryPath = [self getTheCurrrentDirectoryPathForLogs:DirectoryNameForSavingLogs];
    NSArray *arrContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:strDirectoryPath error:nil];
    for (NSString *fileName in arrContents)  {
        
        [[NSFileManager defaultManager] removeItemAtPath:[strDirectoryPath stringByAppendingPathComponent:fileName] error:NULL];
    }
}

#pragma mark - File Related Utility 

- (NSString *)createNewLogFileName {
    
    NSString *appName = [self fetchApplicationName];
    NSDateFormatter *dateFormatter = [self logFileDateFormatter];
    NSString *formattedDate = [dateFormatter stringFromDate:[NSDate date]];
    return [NSString stringWithFormat:@"%@ %@.html", appName, formattedDate];
    
}

-(void)createNewFileWithName:(NSString *)strFileName withHeaderMessage:(NSString *)strHeaderMessage{
    
    NSString *strFilePath = [[self getTheCurrrentDirectoryPathForLogs:DirectoryNameForSavingLogs]  stringByAppendingPathComponent:strFileName];
    if(![[NSFileManager defaultManager]  fileExistsAtPath:strFilePath])
    {
        [strHeaderMessage writeToFile:strFilePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }
}

-(NSString *)getTheCurrentFilePathForLogs:(NSString *)strFileName {
    
    return  [[self getTheCurrrentDirectoryPathForLogs:DirectoryNameForSavingLogs] stringByAppendingPathComponent:strFileName];
}

-(NSString *)getTheCurrrentDirectoryPathForLogs:(NSString *)strDirectoryName {
    
    NSString *strDocumentDirectory  = [self fetchTheDocumentDirectoryPath];
    return  [strDocumentDirectory stringByAppendingPathComponent:DirectoryNameForSavingLogs];
}

- (void)createDirectoryWithName:(NSString *) strDirectoryName {
    
    NSString *strDocumentDirectory  = [self fetchTheDocumentDirectoryPath];
    NSString *strDirectoryPath = [strDocumentDirectory stringByAppendingPathComponent:DirectoryNameForSavingLogs];
    if(![[NSFileManager defaultManager] fileExistsAtPath:strDirectoryPath]){
        
        [[NSFileManager defaultManager]createDirectoryAtPath:strDirectoryPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
}

- (NSString *)fetchTheDocumentDirectoryPath {
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    return docsDir;
    
}


#pragma mark - Utiltiy

-(NSString *)formattingToHTMLLog:(NSString *)strMessage withLogType:(LogFlag)logFlag {
    
    NSString *strHtmlMessage = nil;
    switch (logFlag) {
        case LogFlag_Error:
            strHtmlMessage = [NSString stringWithFormat:@"<p style=\"BACKGROUND-COLOR:LightCoral\" /> %@ </p>",strMessage];
            break;
        case LogFlag_Warning :
            strHtmlMessage = [NSString stringWithFormat:@"<p style=\"BACKGROUND-COLOR:Gold\" /> %@ </p>",strMessage];
            break;
        case LogFlag_Info :
            strHtmlMessage = [NSString stringWithFormat:@"<p style=\"color:black\" /> %@ </p>",strMessage];
            break;
        case LogFlag_Debug:
            strHtmlMessage = [NSString stringWithFormat:@"<p style=\"BACKGROUND-COLOR:CornflowerBlue\" /> %@ </p>",strMessage];
            break;
        default:
            break;
    }
    
    return strHtmlMessage;
}

-(NSString *)addingEmojiToLogMessage:(NSString *)strMessage withLogType:(LogFlag)logFlag {
    
    NSString *strEmojiMessage = nil;
    switch (logFlag) {
        case LogFlag_Error:
            strEmojiMessage = [NSString stringWithFormat:@"❌ %@",strMessage];
            break;
        case LogFlag_Warning :
            strEmojiMessage = [NSString stringWithFormat:@"⚠️ %@",strMessage];
            break;
        case LogFlag_Info :
            strEmojiMessage = strMessage;
            break;
        case LogFlag_Debug:
            strEmojiMessage = [NSString stringWithFormat:@"🔍 %@",strMessage];
            break;
        default:
            break;
    }
    
    return strEmojiMessage;
    
}

-(BOOL)hasThresholdReached:(NSString *)strLogMessage withThreshold:(NSInteger)intThreshold {
    
        NSData* dataLog = [strLogMessage dataUsingEncoding:NSUTF8StringEncoding];
        NSInteger intDataLogLength = dataLog.length;
        return intDataLogLength >= intThreshold ? YES : NO ;
}

- (NSString *)fetchApplicationName {
    static NSString *_appName;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        
        if (!_appName) {
            _appName = [[NSProcessInfo processInfo] processName];
        }
        
        if (!_appName) {
            _appName = @"";
        }
    });
    
    return _appName;
}

-(NSString *)getTheHeaderMessageForFile {
    
    NSString *strDevicePlatform = [self getTheDeviceName];
    NSString *strApplicationName = [self fetchApplicationName];
    NSString *strDeviceVersion = [self getDeviceVersion];
    return [NSString stringWithFormat:@"Application Name : %@ <br> DevicePlatform: %@ <br> DeviceVersion: %@ <br>",strApplicationName,strDevicePlatform,strDeviceVersion];
    
}

#pragma mark - Device Related Utility

-(NSString *)getDeviceVersion {
    
    return [[UIDevice currentDevice] systemVersion];
}

-(NSString *)getTheDeviceName  {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *strCode =  [NSString stringWithCString:systemInfo.machine
                                            encoding:NSUTF8StringEncoding];
    
    
    
    NSDictionary* deviceNamesByCode =
    @{@"i386"      :@"Simulator",
      @"x86_64"    :@"Simulator",
      @"iPod1,1"   :@"iPod Touch",        // (Original)
      @"iPod2,1"   :@"iPod Touch",        // (Second Generation)
      @"iPod3,1"   :@"iPod Touch",        // (Third Generation)
      @"iPod4,1"   :@"iPod Touch",        // (Fourth Generation)
      @"iPod7,1"   :@"iPod Touch",        // (6th Generation)
      @"iPhone1,1" :@"iPhone",            // (Original)
      @"iPhone1,2" :@"iPhone",            // (3G)
      @"iPhone2,1" :@"iPhone",            // (3GS)
      @"iPad1,1"   :@"iPad",              // (Original)
      @"iPad2,1"   :@"iPad 2",            //
      @"iPad3,1"   :@"iPad",              // (3rd Generation)
      @"iPhone3,1" :@"iPhone 4",          // (GSM)
      @"iPhone3,3" :@"iPhone 4",          // (CDMA/Verizon/Sprint)
      @"iPhone4,1" :@"iPhone 4S",         //
      @"iPhone5,1" :@"iPhone 5",          // (model A1428, AT&T/Canada)
      @"iPhone5,2" :@"iPhone 5",          // (model A1429, everything else)
      @"iPad3,4"   :@"iPad",              // (4th Generation)
      @"iPad2,5"   :@"iPad Mini",         // (Original)
      @"iPhone5,3" :@"iPhone 5c",         // (model A1456, A1532 | GSM)
      @"iPhone5,4" :@"iPhone 5c",         // (model A1507, A1516, A1526 (China), A1529 | Global)
      @"iPhone6,1" :@"iPhone 5s",         // (model A1433, A1533 | GSM)
      @"iPhone6,2" :@"iPhone 5s",         // (model A1457, A1518, A1528 (China), A1530 | Global)
      @"iPhone7,1" :@"iPhone 6 Plus",     //
      @"iPhone7,2" :@"iPhone 6",          //
      @"iPhone8,1" :@"iPhone 6S",         //
      @"iPhone8,2" :@"iPhone 6S Plus",    //
      @"iPhone8,4" :@"iPhone SE",         //
      @"iPhone9,1" :@"iPhone 7",          //
      @"iPhone9,3" :@"iPhone 7",          //
      @"iPhone9,2" :@"iPhone 7 Plus",     //
      @"iPhone9,4" :@"iPhone 7 Plus",     //
      
      @"iPad4,1"   :@"iPad Air",          // 5th Generation iPad (iPad Air) - Wifi
      @"iPad4,2"   :@"iPad Air",          // 5th Generation iPad (iPad Air) - Cellular
      @"iPad4,4"   :@"iPad Mini",         // (2nd Generation iPad Mini - Wifi)
      @"iPad4,5"   :@"iPad Mini",         // (2nd Generation iPad Mini - Cellular)
      @"iPad4,7"   :@"iPad Mini",         // (3rd Generation iPad Mini - Wifi (model A1599))
      @"iPad6,7"   :@"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1584)
      @"iPad6,8"   :@"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1652)
      @"iPad6,3"   :@"iPad Pro (9.7\")",  // iPad Pro 9.7 inches - (model A1673)
      @"iPad6,4"   :@"iPad Pro (9.7\")"   // iPad Pro 9.7 inches - (models A1674 and A1675)
      };
    
    NSString* deviceName = [deviceNamesByCode objectForKey:strCode];
    if(deviceName != nil)
        return deviceName;
    else
        return [NSString stringWithFormat:@"Device Code :  %@",strCode];
    
}

#pragma mark - Date Related Utility

- (NSDateFormatter *)logFileDateFormatter {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH-mm-ss"];
    
    return dateFormatter;
}

-(NSString *)convertTheDateToString:(NSDate *)date withFormatter:(NSDateFormatter *)dateFormatter {
    
    NSString *strFormattedDate = [dateFormatter stringFromDate:date];
    return strFormattedDate;
}



@end
