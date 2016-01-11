//
//  STPCameraManager.h
//  STPCamera
//
//  Created by 1amageek on 2015/10/30.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

@import UIKit;
@import AVFoundation;
@import CoreMotion;
@import CoreLocation;
@import CoreImage;
@import CoreVideo;
@import ImageIO;
@import Photos;
@import MobileCoreServices;

#define FRAME_COUNT 5

@protocol STPCameraManagerDelegate;
@interface STPCameraManager : NSObject <CLLocationManagerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, weak) id <STPCameraManagerDelegate> delegate;

@property (nonatomic, readonly) AVCaptureSession *captureSession;
@property (nonatomic, readonly) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, readonly) AVCaptureStillImageOutput *captureStillImageOutput;
@property (nonatomic, readonly) AVCaptureVideoDataOutput *captureVideoDataOutput;

@property (nonatomic, readonly) UIDeviceOrientation deviceOrientation;
@property (nonatomic, readonly) UIInterfaceOrientation interfaceOrientation;

@property (nonatomic, readonly) BOOL hasMultipleCaptureDevices;
@property (nonatomic, readonly) BOOL hasFlash;

@property (nonatomic, readonly) AVCaptureDevicePosition devicePosition;
@property (nonatomic, readonly) AVCaptureFlashMode flashMode;

@property (nonatomic, readonly) CMMotionManager* motionManager;
@property (nonatomic, readonly) CLLocationManager *locationManager;


+ (instancetype)sharedManager;
- (void)requestAuthorization;
- (void)stopRunning;
- (void)startRunning;
- (void)setupAVCaptureCompletionHandler:(void (^)(AVCaptureVideoPreviewLayer *previewLayer))handler;
- (void)terminate;

- (void)setCaptureDevicePosition:(AVCaptureDevicePosition)devicePosition;
- (void)setCaptureFlashMode:(AVCaptureFlashMode)flashMode;
- (void)setOptimizeAtPoint:(CGPoint)point;
- (void)captureImageWithCompletionHandler:(void (^)(UIImage *image, CLLocation *location, NSDictionary *metaData, NSError *error))handler;

- (CGPoint)convertToPointOfInterestFrom:(CGRect)frame coordinates:(CGPoint)viewCoordinates layer:(AVCaptureVideoPreviewLayer *)layer;

@end

@protocol STPCameraManagerDelegate <NSObject>

- (void)cameraManagerReady:(STPCameraManager *)cameraManager;
- (void)cameraManager:(STPCameraManager *)cameraManager didFailWithError:(NSError *)error;
- (void)cameraManager:(STPCameraManager *)cameraManager didChangeCaptureDevicePosition:(AVCaptureDevicePosition)devicePosition;
- (void)cameraManager:(STPCameraManager *)cameraManager didChangeFlashMode:(AVCaptureFlashMode)flashMode;
- (void)cameraManager:(STPCameraManager *)cameraManager didDetectionFeatures:(NSArray <CIFaceFeature *>*)features aperture:(CGRect)aperture;
//- (void)cameraManager:(STPCameraManager *)cameraManager didOptimizeFocus:(BOOL)focus expose:(BOOL)expose; //FIXME

@end