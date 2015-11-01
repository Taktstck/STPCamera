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

@interface STPCameraPreviewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, readonly) UICollectionView *collectionView;
@property (nonatomic) PHFetchResult *assetsFetchResults;
@property (nonatomic) PHAssetCollection *assetCollection;

@end
