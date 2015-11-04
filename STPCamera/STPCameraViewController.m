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
#import "STPCameraPreviewController.h"

@interface STPCameraViewController () <STPCameraManagerDelegate, STPCameraViewDelegate>

@property (nonatomic) STPCameraView *cameraView;
@property (nonatomic) UIView *preview;

@property (nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic) STPCameraPreviewController *previewController;

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
    /*
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
            [STPCameraManager sharedManager].captureDeviceInput = cameraInput;
            [STPCameraManager sharedManager].captureStillImageOutput = stillImageOut;
            [STPCameraManager sharedManager].delegate = self;
            self.view.layer.masksToBounds = YES;
            [self.view.layer insertSublayer:_captureVideoPreviewLayer atIndex:0];
        });
    });*/
    
    [[STPCameraManager sharedManager] setDelegate:self];
    [[STPCameraManager sharedManager] setupAVCaptureCompletionHandler:^(AVCaptureVideoPreviewLayer *previewLayer) {
        _captureVideoPreviewLayer = previewLayer;
        _captureVideoPreviewLayer.frame = self.view.bounds;
        _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.view.layer.masksToBounds = YES;
        [self.view.layer insertSublayer:_captureVideoPreviewLayer atIndex:0];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupAVCapture];
    
    //[self addChildViewController:self.previewController];
    //[self.view addSubview:self.previewController.view];
    //[self.previewController didMoveToParentViewController:self];
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

- (STPCameraPreviewController *)previewController
{
    if (_previewController) {
        return _previewController;
    }
    _previewController = [STPCameraPreviewController new];
    _previewController.view.frame = UIEdgeInsetsInsetRect(self.view.bounds, UIEdgeInsetsMake(self.cameraView.topToolbar.bounds.size.height, 0, self.cameraView.bottomToolbar.bounds.size.height, 0));
    return _previewController;
}

#pragma mark - STPCameraViewDelegate

- (AVCaptureFlashMode)captureFlashMode
{
    return [STPCameraManager sharedManager].flashMode;
}

- (AVCaptureDevicePosition)captureDevicePosition
{
    return [STPCameraManager sharedManager].devicePosition;
}

- (void)cameraView:(STPCameraView *)cameraView changeCaptureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition
{
    [[STPCameraManager sharedManager] setCaptureDevicePosition:captureDevicePosition];
}

- (void)cameraView:(STPCameraView *)cameraView changeCaptureFlashMode:(AVCaptureFlashMode)flashMode
{
    [[STPCameraManager sharedManager] setCaptureFlashMode:flashMode];
}

- (void)cameraView:(STPCameraView *)cameraView optimizeAtPoint:(CGPoint)point
{
    CGPoint convertPoint = [[STPCameraManager sharedManager] convertToPointOfInterestFrom:self.captureVideoPreviewLayer.frame coordinates:point layer:self.captureVideoPreviewLayer];
    [[STPCameraManager sharedManager] setOptimizeAtPoint:convertPoint];
}

- (void)cameraViewStartRecording:(STPCameraMode)cameraMode
{
    if (cameraMode != STPCameraModeShot) {
        return;
    }

#if TARGET_IPHONE_SIMULATOR
    

    CGRect rect = self.view.bounds;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 1.0f);
    [[UIColor colorWithHue:(float)(rand() % 100) / 100 saturation:1.0 brightness:1.0 alpha:1.0] setFill];
    UIRectFillUsingBlendMode(rect, kCGBlendModeNormal);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (image) {
        __block NSString *localIdentifier;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            // Create PHAsset from UIImage
            PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            
            PHObjectPlaceholder *assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset;
            localIdentifier = assetPlaceholder.localIdentifier;
            
            // Add PHAsset to PHAssetCollection
            /*
             PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.previewController.assetCollection];
             [assetCollectionChangeRequest addAssets:@[assetPlaceholder]];
             */
        } completionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"creating Asset Error: %@", error);
            } else {
            
            }
        }];
        
    }
    
#else
    
    [[STPCameraManager sharedManager] captureImageWithCompletionHandler:^(UIImage *image, CLLocation *location, NSDictionary *metaData, NSError *error) {
        if (error) {
            return ;
        }
        
        if (image) {
            __block NSString *localIdentifier;
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                // Create PHAsset from UIImage
                PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                
                PHObjectPlaceholder *assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset;
                localIdentifier = assetPlaceholder.localIdentifier;
                
                // Add PHAsset to PHAssetCollection
                /*
                PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.previewController.assetCollection];
                [assetCollectionChangeRequest addAssets:@[assetPlaceholder]];
                */
            } completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    NSLog(@"creating Asset Error: %@", error);
                } else {

                    PHFetchResult *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
                    PHAsset *asset = assets[0];
                    if (location) {
                        // add location data
                        if ([asset canPerformEditOperation:PHAssetEditOperationProperties]) {
                            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:asset];
                                [request setLocation:location];
                            } completionHandler:^(BOOL success, NSError *error) {
                                if (success) {
                                    NSLog(@"%s add location data success", __PRETTY_FUNCTION__);
                                }
                            }];
                        }
                    } else {
                        NSLog(@"latitude or longitude value is nil");
                    }
                }
            }];
            
        }
    }];
#endif
}

#pragma cameraManagerDelegate

- (void)cameraManagerReady:(STPCameraManager *)cameraManager
{
    [self.cameraView drawAtPoint:self.view.center remove:YES];
}

- (void)cameraManager:(STPCameraManager *)cameraMnager didChangeCaptureDevicePosition:(AVCaptureDevicePosition)devicePosition
{
    
}

- (void)cameraManager:(STPCameraManager *)cameraMnager didChangeFlashMode:(AVCaptureFlashMode)flashMode
{
    
}

- (void)cameraManager:(STPCameraManager *)cameraManager didOptimizeFocus:(BOOL)focus expose:(BOOL)expose
{
    
}

- (void)cameraManager:(STPCameraManager *)cameraManager didFailWithError:(NSError *)error
{
    
}


#pragma mark - memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[STPCameraManager sharedManager] terminate];
}

@end
