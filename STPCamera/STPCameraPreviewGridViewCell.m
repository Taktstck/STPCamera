//
//  STPCameraPreviewGridViewCell.m
//  STPCamera
//
//  Created by 1amageek on 2015/11/01.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import "STPCameraPreviewGridViewCell.h"

@interface STPCameraPreviewGridViewCell ()

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIImageView *livePhotoBadgeImageView;

@end

@implementation STPCameraPreviewGridViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.livePhotoBadgeImageView];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
    self.livePhotoBadgeImageView.image = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.livePhotoBadgeImageView.frame = self.bounds;
}

- (UIImageView *)imageView
{
    if (_imageView) {
        return _imageView;
    }
    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    return _imageView;
}

- (UIImageView *)livePhotoBadgeImageView
{
    if (_livePhotoBadgeImageView) {
        return _livePhotoBadgeImageView;
    }
    _livePhotoBadgeImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _livePhotoBadgeImageView.contentMode = UIViewContentModeScaleAspectFit;
    _livePhotoBadgeImageView.clipsToBounds = YES;
    return _livePhotoBadgeImageView;
}

#pragma mark - setter

- (void)setThumbnailImage:(UIImage *)thumbnailImage
{
    _thumbnailImage = thumbnailImage;
    self.imageView.image = thumbnailImage;
    [self.imageView setNeedsDisplay];
}

- (void)setLivePhotoBadgeImage:(UIImage *)livePhotoBadgeImage
{
    _livePhotoBadgeImage = livePhotoBadgeImage;
    self.livePhotoBadgeImageView.image = livePhotoBadgeImage;
    [self.livePhotoBadgeImageView setNeedsDisplay];
}

@end
