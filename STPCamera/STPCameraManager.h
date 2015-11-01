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
@import ImageIO;

@protocol STPCameraManagerDelegate;
@interface STPCameraManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, weak) id <STPCameraManagerDelegate> delegate;

@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureDeviceInput *deviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOut;
@property (nonatomic, readonly) UIDeviceOrientation deviceOrientation;
@property (nonatomic, readonly) UIInterfaceOrientation interfaceOrientation;

@property (nonatomic, readonly) BOOL hasMultipleCameras;
@property (nonatomic, readonly) BOOL hasFlash;
@property (nonatomic, readonly) BOOL isTraking;

@property (nonatomic, readonly) CMMotionManager* motionManager;
@property (nonatomic, readonly) CLLocationManager *locationManager;


+ (instancetype)sharedManager;
- (void)start;

- (void)changeCamara;
- (void)setFlashMode:(AVCaptureFlashMode)flashMode;


- (void)captureImageWithCompletionHandler:(void (^)(UIImage *image, CLLocation *location, NSDictionary *metaData, NSError *error))handler;
- (CGPoint)convertToPointOfInterestFrom:(CGRect)frame coordinates:(CGPoint)viewCoordinates layer:(AVCaptureVideoPreviewLayer *)layer;


- (void)optimizeAtPoint:(CGPoint)point;
- (void)focusAtPoint:(CGPoint)point;
- (void)exposureAtPoint:(CGPoint)point;

- (void)terminate;

@end

@protocol STPCameraManagerDelegate <NSObject>

- (void)cameraManager:(STPCameraManager *)manager readyForLocationManager:(CLLocationManager *)locationManager;
- (void)cameraManager:(STPCameraManager *)manager error:(NSError *)error;

@end