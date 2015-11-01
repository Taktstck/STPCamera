//
//  STPCameraView.h
//  STPCamera
//
//  Created by 1amageek on 2015/10/30.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

@import UIKit;
@import AVFoundation;

#import <pop/POP.h>
#import <pop/POPLayerExtras.h>

@protocol STPCameraViewDelegate;
@interface STPCameraView : UIView

@property (nonatomic) id <STPCameraViewDelegate> delegate;
- (void)drawAtPoint:(CGPoint)point remove:(BOOL)remove;

@end

@protocol STPCameraViewDelegate <NSObject>
- (void)cameraViewStartRecording;
- (void)changeCamera;
- (void)flashMode:(AVCaptureFlashMode)flashMode;
- (void)cancel;
@optional
- (void)cameraView:(STPCameraView *)cameraView focusAtPoint:(CGPoint)point;
- (void)cameraView:(STPCameraView *)cameraView exposeAtPoint:(CGPoint)point;
- (void)cameraView:(STPCameraView *)cameraView optimizeAtPoint:(CGPoint)point;
@end