//
//  STPCameraView.h
//  STPCamera
//
//  Created by 1amageek on 2015/10/30.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

@import UIKit;
@import AVFoundation;
@import CoreImage;
@import CoreVideo;

#import <pop/POP.h>
#import <pop/POPLayerExtras.h>

@interface STPCameraViewToolbar : UIToolbar
@end

typedef NS_ENUM(NSInteger, STPCameraMode) {
    STPCameraModeShot = 0,
    STPCameraModeBurst,
    STPCameraModeVideo,
    STPCameraModeCount
};

@protocol STPCameraViewDelegate;
@interface STPCameraView : UIView

@property (nonatomic, readonly) STPCameraViewToolbar *topToolbar;
@property (nonatomic, readonly) UIView *bottomToolbar;
@property (nonatomic) id <STPCameraViewDelegate> delegate;

- (void)drawOptimizeCircleAtPoint:(CGPoint)point remove:(BOOL)remove;
- (void)drawFaceBoxesForFeatures:(NSArray <CIFaceFeature *>*)features aperture:(CGRect)aperture onPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer;

@end

@protocol STPCameraViewDelegate <NSObject>
@optional
- (BOOL)cameraViewShouldBeginRecording:(STPCameraView *)cameraView;
- (BOOL)cameraViewShouldBeginOptimize:(STPCameraView *)cameraView;
- (BOOL)cameraViewShouldChangeCaptureDevicePosition:(STPCameraView *)cameraView;
- (BOOL)cameraViewShouldChangeCaptureFlashMode:(STPCameraView *)cameraView;

@required
- (AVCaptureFlashMode)captureFlashMode;
- (AVCaptureDevicePosition)captureDevicePosition;

- (void)cameraViewStartRecording:(STPCameraMode)cameraMode;
- (void)cameraView:(STPCameraView *)cameraView optimizeAtPoint:(CGPoint)point;
- (void)cameraView:(STPCameraView *)cameraView changeCaptureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition;
- (void)cameraView:(STPCameraView *)cameraView changeCaptureFlashMode:(AVCaptureFlashMode)flashMode;
@end