//
//  STPCameraViewController.h
//  STPCamera
//
//  Created by 1amageek on 2015/10/30.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

@import UIKit;

@interface STPCameraViewController : UIViewController

+ (void)requestAccessCameraCompletionHandler:(void (^)(BOOL authorized))handler;
- (void)cameraViewStartRecording;

@end
