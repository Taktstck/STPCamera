//
//  NSDateFormatter+Exif.m
//  STPCamera
//
//  Created by 1amageek on 2015/10/31.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import "NSDateFormatter+Exif.h"

@implementation NSDateFormatter (Exif)

+ (NSDateFormatter *)exifDateFormatter
{
    static NSDateFormatter *dateFormatter;
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy:MM:dd HH:mm:ss";
    }
    
    return dateFormatter;
}

+ (NSDateFormatter *)GPSDateFormatter
{
    static NSDateFormatter *dateFormatter;
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy:MM:dd";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    }
    
    return dateFormatter;
}

+ (NSDateFormatter *)GPSTimeFormatter
{
    static NSDateFormatter *dateFormatter;
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"HH:mm:ss.SSSSSS";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    }
    
    return dateFormatter;
}

+ (NSDateFormatter *)fileNameDateFormatter
{
    static NSDateFormatter *dateFormatter;
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyyMMddHHmmss";
    }
    
    return dateFormatter;
}

@end
