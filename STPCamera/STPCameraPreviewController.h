//
//  STPCameraPreviewController.h
//  STPCamera
//
//  Created by 1amageek on 2015/11/01.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

@import UIKit;
@import Photos;
@import PhotosUI;

#import <pop/POP.h>
#import <pop/POPLayerExtras.h>

typedef NS_ENUM(NSInteger, STPCameraPreviewSection) {
    STPCameraPreviewSectionPreview = 0,
    STPCameraPreviewSectionCamera = 1,
    //STPCameraPreviewSectionVideo,
    STPCameraPreviewSectionCount
};


@interface STPCameraPreviewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, readonly) UICollectionView *collectionView;
@property (nonatomic, readonly, getter=isProcessing) BOOL processing;

@property (nonatomic) PHFetchResult *assetsFetchResults;
@property (nonatomic) PHAssetCollection *assetCollection;

@end
