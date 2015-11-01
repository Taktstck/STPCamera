//
//  STPCameraViewController.m
//  STPCamera
//
//  Created by 1amageek on 2015/10/30.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import "STPCameraViewController.h"
#import "STPCameraManager.h"
#import "STPCameraView.h"

@interface STPCameraViewController () <STPCameraManagerDelegate, STPCameraViewDelegate>

@property (nonatomic) STPCameraView *cameraView;
@property (nonatomic) UIView *preview;
@property (nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@end

@implementation STPCameraViewController


+ (void)requestAccessCameraCompletionHandler:(void (^)(BOOL authorized))handler
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusAuthorized: {
            // プライバシー設定でカメラの使用が許可されている場合
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(YES);
            });
            break;
        }
        case AVAuthorizationStatusDenied: {
            // プライバシー設定でカメラの使用が禁止されている場合
            handler(NO);
            break;
        }
        case AVAuthorizationStatusRestricted: {
            // 機能制限の場合とあるが、実際にこの値をとることがなかった
            handler(NO);
            break;
        }
        case AVAuthorizationStatusNotDetermined: {
            // 初回起動時に許可設定を促すダイアログが表示される
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    // 許可された場合の処理
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler(YES);
                    });
                } else {
                    // 許可してもらえない場合
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler(NO);
                    });
                }
            }];
            break;
        }
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)loadView
{
    [super loadView];
    [self.view addSubview:self.cameraView];
}

- (void)setupAVCapture
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSError *error = nil;
        AVCaptureSession *session = [AVCaptureSession new];
        AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput *cameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:camera error:&error];
        AVCaptureStillImageOutput *stillImageOut = [AVCaptureStillImageOutput new];
        
        if ([session canAddInput:cameraInput]) {
            [session addInput:cameraInput];
        }
        
        if ([session canAddOutput:stillImageOut]) {
            [session addOutput:stillImageOut];
        }
        
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        _captureVideoPreviewLayer.frame = self.view.bounds;
        _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [session startRunning];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [STPCameraManager sharedManager].captureSession = session;
            [STPCameraManager sharedManager].deviceInput = cameraInput;
            [STPCameraManager sharedManager].stillImageOut = stillImageOut;
            [STPCameraManager sharedManager].delegate = self;
            self.view.layer.masksToBounds = YES;
            [self.view.layer insertSublayer:_captureVideoPreviewLayer atIndex:0];
        });
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupAVCapture];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.cameraView drawAtPoint:self.view.center remove:YES];
}

#pragma mark - Elements

- (STPCameraView *)cameraView
{
    if (_cameraView) {
        return _cameraView;
    }
    _cameraView = [[STPCameraView alloc] initWithFrame:self.view.bounds];
    _cameraView.delegate = self;
    return _cameraView;
}

#pragma mark - Camera view delegate

- (void)changeCamera
{
    [[STPCameraManager sharedManager] changeCamara];
}

- (void)flashMode:(AVCaptureFlashMode)flashMode
{
    [[STPCameraManager sharedManager] setFlashMode:flashMode];
}

- (void)cameraView:(STPCameraView *)cameraView optimizeAtPoint:(CGPoint)point
{
    CGPoint convertPoint = [[STPCameraManager sharedManager] convertToPointOfInterestFrom:self.captureVideoPreviewLayer.frame coordinates:point layer:self.captureVideoPreviewLayer];
    [[STPCameraManager sharedManager] optimizeAtPoint:convertPoint];
}

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewStartRecording
{
#if TARGET_IPHONE_SIMULATOR
    
    CGFloat r = (random() % 100 + 10)/100.0f;
    CGFloat g = (random() % 100 + 10)/100.0f;
    CGFloat b = (random() % 100 + 10)/100.0f;
    UIImage *image;
    UIGraphicsBeginImageContext(self.view.bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, r, g, b, 1.0);
    CGContextAddRect(context,self.view.bounds);
    CGContextFillPath(context);
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
#else
    [[STPCameraManager sharedManager] captureImageWithCompletionHandler:^(UIImage *image, CLLocation *location, NSDictionary *metaData, NSError *error) {
        if (error) {
            return ;
        }
        
        if (image) {

        }
    }];
#endif
}

- (void)cameraManager:(STPCameraManager *)manager error:(NSError *)error
{
    NSLog(@"%@", error);
}


#pragma mark - CameraManager

- (void)cameraManager:(STPCameraManager *)manager readyForLocationManager:(CLLocationManager *)locationManager
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)dealloc
{
    [[STPCameraManager sharedManager] terminate];
}

#pragma mark - memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
