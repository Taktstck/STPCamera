//
//  NSDateFormatter+Exif.h
//  STPCamera
//
//  Created by 1amageek on 2015/10/31.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDateFormatter (Exif)

+ (NSDateFormatter *)exifDateFormatter;
+ (NSDateFormatter *)GPSDateFormatter;
+ (NSDateFormatter *)GPSTimeFormatter;
+ (NSDateFormatter *)fileNameDateFormatter;

@end
