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


@interface STPCameraViewController () <STPCameraManagerDelegate, STPCameraViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

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
    [self.cameraView drawOptimizeCircleAtPoint:self.view.center remove:YES];
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

- (void)cameraManager:(STPCameraManager *)cameraManager didDetectionFeatures:(NSArray<CIFaceFeature *> *)features aperture:(CGRect)aperture
{
    [self.cameraView drawFaceBoxesForFeatures:features aperture:aperture onPreviewLayer:self.captureVideoPreviewLayer];
}

- (CALayer *)layerForName:(NSString *)name inLayers:(NSArray <CALayer *>*)layers
{
    __block CALayer *layer = nil;
    [layers enumerateObjectsUsingBlock:^(CALayer * _Nonnull aLayer, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([aLayer.name isEqualToString:name]) {
            layer = aLayer;
            *stop = YES;
        }
    }];
    return layer;
}

#pragma mark - STPCameraFaceDetectorDelegate

-(void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap
{
    //すでに追加されているレイヤー
    NSArray *sublayers = [NSArray arrayWithArray:[self.captureVideoPreviewLayer sublayers]];
    NSInteger sublayersCount = [sublayers count];
    NSInteger currentSublayer = 0;
    
    //描画内容の用意
    NSString *faceLayerName = @"FaceLayer";
    NSString *rightEyeLayerName = @"RightEyeLayer";
    NSString *leftEyeLayerName = @"LeftEyeLayer";
    NSString *mouthLayerName = @"mouthLayer";
    NSString *noseLayerName = @"noseLayer";
    
    //CALayerのアニメーション開始
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    //レイヤーの非表示
    for ( CALayer *layer in sublayers ) {
        if ( [[layer name] isEqualToString:faceLayerName] ||
            [[layer name] isEqualToString:rightEyeLayerName] ||
            [[layer name] isEqualToString:leftEyeLayerName] ||
            [[layer name] isEqualToString:mouthLayerName] ||
            [[layer name] isEqualToString:noseLayerName]) {
            layer.hidden = YES;
        }
    }
    
    //描画領域の取得
    CGSize parentFrameSize = [self.view frame].size;
    NSString *gravity = [self.captureVideoPreviewLayer videoGravity];
    CGRect previewBox = [self videoPreviewBoxForGravity:gravity
                                                        frameSize:parentFrameSize
                                                     apertureSize:clap.size];
    
    //表示サイズとの比率
    CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
    CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
    
    //取得した顔認証のデータを解読
    for(CIFaceFeature *faceFeature in features ) {
        /*-----------------
         輪郭の位置を描画
         -----------------*/
        //輪郭の位置を取得
        CGRect faceRect = [faceFeature bounds];
        CGFloat temp = faceRect.size.width;
        faceRect.size.width = faceRect.size.height;
        faceRect.size.height = temp;
        temp = faceRect.origin.x;
        faceRect.origin.x = faceRect.origin.y;
        faceRect.origin.y = temp;
        faceRect.size.width *= widthScaleBy;
        faceRect.size.height *= heightScaleBy;
        faceRect.origin.x *= widthScaleBy;
        faceRect.origin.y *= heightScaleBy;
        CALayer *faceLayer = nil;
        while ( !faceLayer && (currentSublayer < sublayersCount) ) {
            CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
            if ( [[currentLayer name] isEqualToString:faceLayerName] ) {
                faceLayer = currentLayer;
                [currentLayer setHidden:NO];
            }
        }
        if (!faceLayer) {
            faceLayer = [CALayer new];
            faceLayer.borderWidth = 1.0;
            faceLayer.borderColor = [UIColor greenColor].CGColor;
            [faceLayer setName:faceLayerName];
            [self.captureVideoPreviewLayer addSublayer:faceLayer];
        }
        [faceLayer setFrame:faceRect];
        
        /*---------------
         右目の位置を描画
         ---------------*/
        if(faceFeature.hasRightEyePosition){
            CGRect rightEyeRect;
            
            //画像上での中心座標を設定
            CGPoint rightEyePosition = CGPointMake(faceFeature.rightEyePosition.y, faceFeature.rightEyePosition.x);
            rightEyeRect.origin.x = rightEyePosition.x;
            rightEyeRect.origin.y = rightEyePosition.y;
            
            //サイズを設定
            CGSize rightEyeSize = CGSizeMake(faceLayer.bounds.size.width/1.1, faceLayer.bounds.size.height/1.7);
            rightEyeRect.origin.x -= rightEyeSize.width/2;
            rightEyeRect.origin.y -= rightEyeSize.height/2;
            rightEyeRect.size = rightEyeSize;
            
            //比率を変更
            rightEyeRect.size.width *= widthScaleBy;
            rightEyeRect.size.height *= heightScaleBy;
            rightEyeRect.origin.x *= widthScaleBy;
            rightEyeRect.origin.y *= heightScaleBy;
            
            //レイヤーを検索
            CALayer *rightEyeLayer = nil;
            while ( !rightEyeLayer && (currentSublayer < sublayersCount) ) {
                CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
                if ( [[currentLayer name] isEqualToString:rightEyeLayerName] ) {
                    rightEyeLayer = currentLayer;
                    currentLayer.hidden = NO;
                }
            }
            if (!rightEyeLayer) {
                rightEyeLayer = [CALayer new];
                rightEyeLayer.borderWidth = 1.0;
                rightEyeLayer.borderColor = [UIColor yellowColor].CGColor;
                [rightEyeLayer setName:rightEyeLayerName];
                [self.captureVideoPreviewLayer addSublayer:rightEyeLayer];
            }
            [rightEyeLayer setFrame:rightEyeRect];
        }
        
        /*---------------
         左目の位置を描画
         ---------------*/
        if(faceFeature.hasLeftEyePosition){
            CGRect leftEyeRect;
            
            //画像上での中心座標を設定
            CGPoint leftEyePosition = CGPointMake(faceFeature.leftEyePosition.y, faceFeature.leftEyePosition.x);
            leftEyeRect.origin.x = leftEyePosition.x;
            leftEyeRect.origin.y = leftEyePosition.y;
            
            //サイズを設定
            CGSize leftEyeSize = CGSizeMake(faceLayer.bounds.size.width/1.1, faceLayer.bounds.size.height/1.7);
            leftEyeRect.origin.x -= leftEyeSize.width/2;
            leftEyeRect.origin.y -= leftEyeSize.height/2;
            leftEyeRect.size = leftEyeSize;
            
            //比率を変更
            leftEyeRect.size.width *= widthScaleBy;
            leftEyeRect.size.height *= heightScaleBy;
            leftEyeRect.origin.x *= widthScaleBy;
            leftEyeRect.origin.y *= heightScaleBy;
            
            //レイヤーを検索
            CALayer *leftEyeLayer = nil;
            while ( !leftEyeLayer && (currentSublayer < sublayersCount) ) {
                CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
                if ( [[currentLayer name] isEqualToString:leftEyeLayerName] ) {
                    leftEyeLayer = currentLayer;
                    currentLayer.hidden = NO;
                }
            }
            if (!leftEyeLayer) {
                leftEyeLayer = [CALayer new];
                leftEyeLayer.borderWidth = 1.0;
                leftEyeLayer.borderColor = [UIColor blueColor].CGColor;
                [leftEyeLayer setName:leftEyeLayerName];
                [self.captureVideoPreviewLayer addSublayer:leftEyeLayer];
            }
            [leftEyeLayer setFrame:leftEyeRect];
        }
        
        /*---------------
         口の位置を描画
         ---------------*/
        if(faceFeature.hasMouthPosition){
            CGRect mouthRect;
            
            //画像上での中心座標を設定
            CGPoint mouthPosition = CGPointMake(faceFeature.mouthPosition.y, faceFeature.mouthPosition.x);
            mouthRect.origin.x = mouthPosition.x;
            mouthRect.origin.y = mouthPosition.y;
            
            //サイズを設定
            CGSize mouthSize = CGSizeMake(faceLayer.bounds.size.width/0.8, faceLayer.bounds.size.height/1.4);
            mouthRect.origin.x -= mouthSize.width/2;
            mouthRect.origin.y -= mouthSize.height/2;
            mouthRect.size = mouthSize;
            
            //比率を変更
            mouthRect.size.width *= widthScaleBy;
            mouthRect.size.height *= heightScaleBy;
            mouthRect.origin.x *= widthScaleBy;
            mouthRect.origin.y *= heightScaleBy;
            
            //レイヤーを検索
            CALayer *mouthLayer = nil;
            while ( !mouthLayer && (currentSublayer < sublayersCount) ) {
                CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
                if ( [[currentLayer name] isEqualToString:mouthLayerName] ) {
                    mouthLayer = currentLayer;
                    currentLayer.hidden = NO;
                }
            }
            if (!mouthLayer) {
                mouthLayer = [CALayer new];
                mouthLayer.borderWidth = 1.0;
                mouthLayer.borderColor = [UIColor redColor].CGColor;
                [mouthLayer setName:mouthLayerName];
                [self.captureVideoPreviewLayer addSublayer:mouthLayer];
            }
            [mouthLayer setFrame:mouthRect];
        }
        /*---------------
         鼻の位置を描画
         ---------------*/
        /*
        if(faceFeature.hasRightEyePosition && faceFeature.hasLeftEyePosition && faceFeature.hasMouthPosition){
            //右目の中心座標
            CGPoint rightEyePosition = CGPointMake(faceFeature.rightEyePosition.y, faceFeature.rightEyePosition.x);
            rightEyePosition.x *= widthScaleBy;
            rightEyePosition.y *= heightScaleBy;
            
            //左目の中心座標
            CGPoint leftEyePosition = CGPointMake(faceFeature.leftEyePosition.y, faceFeature.leftEyePosition.x);
            leftEyePosition.x *= widthScaleBy;
            leftEyePosition.y *= heightScaleBy;
            
            //口の中心座標
            CGPoint mouthPosition = CGPointMake(faceFeature.mouthPosition.y, faceFeature.mouthPosition.x);
            mouthPosition.x *= widthScaleBy;
            mouthPosition.y *= heightScaleBy;
            
            //右目と左目の中点座標を求める
            CGFloat eyeCenterPositionX = (rightEyePosition.x+leftEyePosition.x)/2;
            CGFloat eyeCenterPositionY = (rightEyePosition.y+leftEyePosition.y)/2;
            CGPoint eyeCenterPosition = CGPointMake(eyeCenterPositionX, eyeCenterPositionY);
            
            //右目と左目でできる円弧の二等分線の角度を求める
            CGFloat eyeBisector = atan((leftEyePosition.y-rightEyePosition.y)/(leftEyePosition.x-rightEyePosition.x))+90;
            
            //左目と口の中点座標を求める
            CGFloat mouthAndLeftEyeCneterPositionX = (leftEyePosition.x+mouthPosition.x)/2;
            CGFloat mouthAndLeftEyeCneterPositionY = (leftEyePosition.y+mouthPosition.y)/2;
            CGPoint mouthAndLeftEyeCneterPosition = CGPointMake(mouthAndLeftEyeCneterPositionX, mouthAndLeftEyeCneterPositionY);
            
            //左目と口でできる円弧の二等分線の角度を求める
            CGFloat mouthAndLeftEyeBisector = atan((mouthPosition.y-leftEyePosition.y)/(mouthPosition.x-leftEyePosition.x))+90;
            
            mouthAndLeftEyeBisector = isnan(mouthAndLeftEyeBisector) ? 0 : mouthAndLeftEyeBisector;
            
            //鼻の中心座標を取得
            CGFloat noseX = eyeCenterPosition.x+((mouthAndLeftEyeCneterPosition.y-eyeCenterPosition.y)-(mouthAndLeftEyeCneterPosition.x-eyeCenterPosition.x)*tan(mouthAndLeftEyeBisector))/(tan(eyeBisector)-tan(mouthAndLeftEyeBisector));
            CGFloat noseY = eyeCenterPosition.y+(noseX-eyeCenterPosition.x)*tan(eyeBisector);
            CGPoint nosePosition = CGPointMake(noseX, noseY);
            
            //中心座標補正
            CGSize noseSize = CGSizeMake(faceLayer.bounds.size.width/1.4*widthScaleBy, faceLayer.bounds.size.height/1.1*heightScaleBy);
            nosePosition.x += noseSize.width/2;
            nosePosition.y -= noseSize.height/8;
            CGRect noseRect;
            noseRect.origin = nosePosition;
            
            //鼻のサイズを設定
            noseRect.origin.x -= noseSize.width/2;
            noseRect.origin.y -= noseSize.height/2;
            noseRect.size = noseSize;
            
            //レイヤーを検索
            CALayer *noseLayer = nil;
            while ( !noseLayer && (currentSublayer < sublayersCount) ) {
                CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
                if ( [[currentLayer name] isEqualToString:noseLayerName] ) {
                    noseLayer = currentLayer;
                    currentLayer.hidden = NO;
                }
            }
            if (!noseLayer) {
                noseLayer = [CALayer new];
                noseLayer.borderWidth = 1.0;
                noseLayer.borderColor = [UIColor purpleColor].CGColor;
                [noseLayer setName:noseLayerName];
                [self.captureVideoPreviewLayer addSublayer:noseLayer];
            }
            NSLog(@"nose %@ %@",noseLayer, NSStringFromCGRect(noseRect));
            [noseLayer setFrame:noseRect];
        }
        */
    }
    
    [CATransaction commit];
}

- (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if([gravity isEqualToString:AVLayerVideoGravityResizeAspect]){
        if(viewRatio > apertureRatio){
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }else{
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    }
    
    CGRect videoBox;
    videoBox.size = size;
    if(size.width < frameSize.width){
        videoBox.origin.x = (frameSize.width - size.width) / 2;
    }else{
        videoBox.origin.x = (size.width - frameSize.width) / 2;
    }
    
    if(size.height < frameSize.height){
        videoBox.origin.y = (frameSize.height - size.height) / 2;
    }else{
        videoBox.origin.y = (size.height - frameSize.height) / 2;
    }
    
    return videoBox;
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
