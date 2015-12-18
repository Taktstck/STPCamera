//
//  STPCameraPreviewGridViewCell.h
//  STPCamera
//
//  Created by 1amageek on 2015/11/01.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface STPCameraPreviewGridViewCell : UICollectionViewCell

@property (nonatomic) UIImage *thumbnailImage;
@property (nonatomic) UIImage *livePhotoBadgeImage;
@property (nonatomic, copy) NSString *representedAssetIdentifier;

@end
