//
//  STPCameraPreviewController.m
//  STPCamera
//
//  Created by 1amageek on 2015/11/01.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import "STPCameraPreviewController.h"
#import "NSIndexSet+Convenience.h"
#import "UICollectionView+Convenience.h"
#import "STPCameraPreviewGridViewCell.h"

@interface STPCameraPreviewControllerView : UIView

@end

@implementation STPCameraPreviewControllerView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self) {
        return nil;
    }
    return view;
}

@end

@interface STPCameraPreviewController () <PHPhotoLibraryChangeObserver, UIGestureRecognizerDelegate>
@property (nonatomic, readwrite) UICollectionView *collectionView;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic) UIEdgeInsets previewInsets;
@property (nonatomic) NSIndexPath *selectedIndexPath;
@property (nonatomic) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic) UIView *gestureView;
@property (nonatomic) NSMutableArray *dustBox;
@property (nonatomic) NSDate *openDate;
@property (nonatomic) CGFloat imageViewTransitionProgress;
@property (nonatomic) UIButton *deleteButton;
@property (nonatomic, readwrite) BOOL processing;
@property CGRect previousPreheatRect;


@end

@implementation STPCameraPreviewController
static inline CGFloat POPTransition(CGFloat progress, CGFloat startValue, CGFloat endValue) {
    return startValue + (progress * (endValue - startValue));
}
static CGFloat kgestureThreshold = 550;
static CGFloat kCollectionViewHeight = 40;
static CGFloat kCollectionViewLayoutSpacing = 1;
static CGFloat kCollectionViewLayoutSizeWidth = 25;
static CGSize AssetGridThumbnailSize;

- (void)loadView
{
    self.view = [[STPCameraPreviewControllerView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    [self.view addSubview:self.gestureView];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.deleteButton];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.processing = NO;
    self.openDate = [NSDate date];
    self.dustBox = @[].mutableCopy;
    self.previewInsets = UIEdgeInsetsMake(16, 16, kCollectionViewHeight + self.deleteButton.bounds.size.height, 16);
    [self.collectionView registerClass:[STPCameraPreviewGridViewCell class] forCellWithReuseIdentifier:@"STPCameraPreviewGridViewCell"];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"UICollectionViewCell"];
    AssetGridThumbnailSize = CGSizeMake(kCollectionViewLayoutSizeWidth, kCollectionViewHeight - kCollectionViewLayoutSpacing * 2);
    PHFetchOptions *takePhotoOptions = [PHFetchOptions new];
    takePhotoOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate >= %@", self.openDate];
    takePhotoOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    self.assetsFetchResults = [PHAsset fetchAssetsWithOptions:takePhotoOptions];
    [self.gestureView addGestureRecognizer:self.panGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)viewWillLayoutSubviews
{
    self.collectionView.frame = CGRectMake(0, self.view.bounds.size.height - kCollectionViewHeight, self.view.bounds.size.width, kCollectionViewHeight);
    self.imageView.frame = UIEdgeInsetsInsetRect(self.view.bounds, self.previewInsets);
    self.deleteButton.center = CGPointMake(self.view.bounds.size.width/2, CGRectGetMaxY(self.imageView.frame) + self.deleteButton.bounds.size.height/2);
}

#pragma mark -

- (UIImageView *)imageView
{
    if (_imageView) {
        return _imageView;
    }
    _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _imageView.transform = CGAffineTransformIdentity;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    return _imageView;
}

- (UICollectionView *)collectionView
{
    if (_collectionView) {
        return _collectionView;
    }
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    CGRect frame = CGRectMake(0, self.view.bounds.size.height - kCollectionViewHeight, self.view.bounds.size.width, kCollectionViewHeight);
    CGFloat sideInset = self.view.bounds.size.width/2 - kCollectionViewLayoutSizeWidth/2 + kCollectionViewLayoutSpacing;
    _collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
    _collectionView.alwaysBounceHorizontal = YES;
    _collectionView.showsHorizontalScrollIndicator = NO;
    //_collectionView.pagingEnabled = YES;
    _collectionView.contentInset = UIEdgeInsetsMake(0, sideInset, 0, sideInset);
    return _collectionView;
}

- (PHCachingImageManager *)imageManager
{
    if (_imageManager) {
        return _imageManager;
    }
    _imageManager = [PHCachingImageManager new];
    return _imageManager;
}

- (UIPanGestureRecognizer *)panGestureRecognizer
{
    if (_panGestureRecognizer) {
        return _panGestureRecognizer;
    }
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    _panGestureRecognizer.delegate = self;
    return _panGestureRecognizer;
}

- (UIView *)gestureView
{
    if (_gestureView) {
        return _gestureView;
    }
    _gestureView = [[UIView alloc] initWithFrame:self.view.bounds];
    _gestureView.backgroundColor = [UIColor clearColor];
    _gestureView.userInteractionEnabled = NO;
    return _gestureView;
}

- (UIButton *)deleteButton
{
    if (_deleteButton) {
        return _deleteButton;
    }
    _deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_deleteButton setTitle:@"Delete this photo." forState:UIControlStateNormal];
    [_deleteButton addTarget:self action:@selector(tapDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
    [_deleteButton sizeToFit];
    _deleteButton.alpha = 0;
    return _deleteButton;
}

#pragma mark - action

- (void)tapDeleteButton:(UIButton *)button
{
    POPBasicAnimation *animation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    animation.fromValue = @(1);
    animation.toValue = @(0);
    animation.duration = 0.33f;
    animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        if (finished) {
            PHAsset *asset = self.assetsFetchResults[self.selectedIndexPath.item];
            [self.dustBox addObject:asset.localIdentifier];
            
            PHFetchOptions *takePhotoOptions = [PHFetchOptions new];
            takePhotoOptions.predicate = [NSPredicate predicateWithFormat:@"(creationDate >= %@) AND (NOT (localIdentifier IN %@))", self.openDate, self.dustBox];
            takePhotoOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
            self.assetsFetchResults = [PHAsset fetchAssetsWithOptions:takePhotoOptions];
            [self.collectionView performBatchUpdates:^{
                [self.collectionView deleteItemsAtIndexPaths:@[self.selectedIndexPath]];
            } completion:^(BOOL finished) {
                
                self.imageView.frame = UIEdgeInsetsInsetRect(self.view.bounds, self.previewInsets);
                self.imageView.layer.opacity = 1;
                self.selectedIndexPath = nil;
                [self scrollViewDidScroll:self.collectionView];
            }];
        }
    };
    [self.imageView.layer pop_addAnimation:animation forKey:@"inc.stamp.stp.camera.dust.opacity"];
}

- (void)panGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.gestureView];
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            
            break;
            
        case UIGestureRecognizerStateChanged:
            self.imageView.center = CGPointMake(self.imageView.center.x + translation.x, self.imageView.center.y + translation.y);
            
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {

            CGPoint velocity = [recognizer velocityInView:self.gestureView];
            CGFloat _velocity = MAX(fabs(velocity.x), fabs(velocity.y));
            
            if (kgestureThreshold < _velocity) {
                
                POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
                animation.velocity = [NSValue valueWithCGPoint:velocity];
                animation.toValue = [NSValue valueWithCGPoint:CGPointMake(velocity.x, velocity.y)];
                animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                    if (finished) {
                        [self.imageView removeFromSuperview];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:STPCameraPreviewSectionCamera] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                        });
                    }
                };
                [self.imageView.layer pop_addAnimation:animation forKey:@"inc.stamp.stp.camera.dust.position"];
            } else {
                CGRect frame = UIEdgeInsetsInsetRect(self.view.bounds, self.previewInsets);
                POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
                positionAnimation.velocity = [NSValue valueWithCGPoint:velocity];
                positionAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))];
                [self.imageView.layer pop_addAnimation:positionAnimation forKey:@"inc.stamp.stp.dust.cancel"];
            }
        }
            break;
            
        default:
            break;
        
    }
    [recognizer setTranslation:CGPointZero inView:self.gestureView];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.panGestureRecognizer) {
        CGPoint location = [gestureRecognizer locationInView:self.gestureView];
        return CGRectContainsPoint(self.imageView.frame, location);
    } else {
        return YES;
    }
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return STPCameraPreviewSectionCount;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == STPCameraPreviewSectionCamera) {
        return 1;
    }
    return self.assetsFetchResults.count;
}



- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == STPCameraPreviewSectionCamera) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UICollectionViewCell" forIndexPath:indexPath];
        cell.backgroundColor = [UIColor blackColor];
        return cell;
    }
    
    
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    
    // Dequeue an AAPLGridViewCell.
    STPCameraPreviewGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"STPCameraPreviewGridViewCell" forIndexPath:indexPath];
    cell.representedAssetIdentifier = asset.localIdentifier;
    
    // Add a badge to the cell if the PHAsset represents a Live Photo.
    if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
        // Add Badge Image to the cell to denote that the asset is a Live Photo.
        UIImage *badge = [PHLivePhotoView livePhotoBadgeImageWithOptions:PHLivePhotoBadgeOptionsOverContent];
        cell.livePhotoBadgeImage = badge;
    }
    
    // Request an image for the asset from the PHCachingImageManager.
    [self.imageManager requestImageForAsset:asset
                                 targetSize:AssetGridThumbnailSize
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  // Set the cell's thumbnail image if it's still showing the same asset.
                                  if ([cell.representedAssetIdentifier isEqualToString:asset.localIdentifier]) {
                                      cell.thumbnailImage = result;
                                  }
                              }];
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return kCollectionViewLayoutSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return kCollectionViewLayoutSpacing;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 1, 0, 1);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kCollectionViewLayoutSizeWidth, kCollectionViewHeight - kCollectionViewLayoutSpacing * 2);
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Update cached assets for the new visible area.
    [self updateCachedAssets];
    
    CGPoint centerPoint = CGPointMake(scrollView.bounds.size.width/2 + scrollView.contentOffset.x, scrollView.bounds.size.height/2);
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:centerPoint];
    if (indexPath) {
        if (indexPath.section == STPCameraPreviewSectionPreview) {
            
            if (![self.imageView isDescendantOfView:self.view]) {
                UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
                CGRect frame = [self.collectionView convertRect:cell.frame toView:self.view];
                self.imageView.frame = frame;
                [self.view addSubview:self.imageView];
                [UIView animateWithDuration:0.2f animations:^{
                    self.imageView.frame = UIEdgeInsetsInsetRect(self.view.bounds, self.previewInsets);
                } completion:^(BOOL finished) {
                    self.gestureView.userInteractionEnabled = YES;
                    self.deleteButton.alpha = 1;
                }];
                
            }
            
            if (indexPath != self.selectedIndexPath) {
                PHAsset *asset = self.assetsFetchResults[indexPath.item];
                
                if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
                    // Add Badge Image to the cell to denote that the asset is a Live Photo.
                    UIImage *badge = [PHLivePhotoView livePhotoBadgeImageWithOptions:PHLivePhotoBadgeOptionsOverContent];
                    self.imageView.image = badge;
                }
                
                // Request an image for the asset from the PHCachingImageManager.
                [self.imageManager requestImageForAsset:asset
                                             targetSize:self.imageView.bounds.size
                                            contentMode:PHImageContentModeAspectFill
                                                options:nil
                                          resultHandler:^(UIImage *result, NSDictionary *info) {
                                              self.imageView.image = result;
                                          }];
                
                
                self.selectedIndexPath = indexPath;
            }
        }
        if (indexPath.section == STPCameraPreviewSectionCamera) {
            [self.imageView removeFromSuperview];
            self.deleteButton.alpha = 0;
        }
    }
}

#pragma mark - Asset Caching

- (void)resetCachedAssets {
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect.
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, -0.5f, 0.0f * CGRectGetHeight(preheatRect));
    /*
     Check if the collection view is showing an area that is significantly
     different to the last preheated area.
     */
    CGFloat delta = ABS(CGRectGetMidX(preheatRect) - CGRectGetMidX(self.previousPreheatRect));
    if (delta > CGRectGetWidth(self.collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        // Update the assets the PHCachingImageManager is caching.
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:AssetGridThumbnailSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:AssetGridThumbnailSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:nil];
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        PHAsset *asset = self.assetsFetchResults[indexPath.item];
        [assets addObject:asset];
    }
    
    return assets;
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    // Check if there are changes to the assets we are showing.
    PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assetsFetchResults];
    if (collectionChanges == nil) {
        return;
    }
    
    /*
     Change notifications may be made on a background queue. Re-dispatch to the
     main queue before acting on the change as we'll be updating the UI.
     */
    self.processing = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        // Get the new fetch result.
        self.assetsFetchResults = [collectionChanges fetchResultAfterChanges];
        
        UICollectionView *collectionView = self.collectionView;
        
        if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
            // Reload the collection view if the incremental diffs are not available
            [collectionView reloadData];
            
        } else {
            /*
             Tell the collection view to animate insertions and deletions if we
             have incremental diffs.
             */
            
            [collectionView performBatchUpdates:^{
                NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
                if ([removedIndexes count] > 0) {
                    [collectionView deleteItemsAtIndexPaths:[removedIndexes aapl_indexPathsFromIndexesWithSection:STPCameraPreviewSectionPreview]];
                }
                
                NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
                if ([insertedIndexes count] > 0) {
                    [collectionView insertItemsAtIndexPaths:[insertedIndexes aapl_indexPathsFromIndexesWithSection:STPCameraPreviewSectionPreview]];
                }
                
                NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
                if ([changedIndexes count] > 0) {
                    [collectionView reloadItemsAtIndexPaths:[changedIndexes aapl_indexPathsFromIndexesWithSection:STPCameraPreviewSectionPreview]];
                }
            } completion:^(BOOL finished) {
                self.processing = NO;
            }];
        }
        
        [self resetCachedAssets];
    });
}


@end
