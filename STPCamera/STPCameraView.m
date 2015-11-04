//
//  STPCameraView.m
//  STPCamera
//
//  Created by 1amageek on 2015/10/30.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import "STPCameraView.h"

@implementation STPCameraViewToolbar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;
        self.translucent = YES;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    
}

@end

@interface STPCameraView ()

@property (nonatomic) UIEdgeInsets insets;

@property (nonatomic) CGPoint triggerButtonCenter;
@property (nonatomic) UIView *triggerButton;


@property (nonatomic) CALayer *triggerButtonOutline;
@property (nonatomic) CALayer *focusBox;
@property (nonatomic) CALayer *exposeBox;

// top toolbar
@property (nonatomic, readwrite) STPCameraViewToolbar *topToolbar;
@property (nonatomic) UIBarButtonItem *flexBarButtonItem;
@property (nonatomic) UIBarButtonItem *fixedBarButtonItem;

// flash
@property (nonatomic) UIBarButtonItem *flashBarButtonItem;
@property (nonatomic) UIBarButtonItem *flashOnBarButtonItem;
@property (nonatomic) UIBarButtonItem *flashOffBarButtonItem;
@property (nonatomic) UIBarButtonItem *flashAutoBarButtonItem;

// device
@property (nonatomic) UIBarButtonItem *devicePositionBarButtonItem;


@property (nonatomic, readwrite) UIView *bottomToolbar;
@property (nonatomic) UIView *contentView;
@property (nonatomic) UIView *shutterView;

@property (nonatomic) CGFloat optimizeProgress;
@property (nonatomic) CGFloat triggerProgress;

@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic) UITapGestureRecognizer *triggerTapGestureRecognizer;
@property (nonatomic) UILongPressGestureRecognizer *triggerLongPressGestureRecognizer;


@property (nonatomic, readonly) AVCaptureFlashMode flashMode;
@property (nonatomic, readonly) AVCaptureDevicePosition devicePosition;

@end

@implementation STPCameraView
static inline CGFloat POPTransition(CGFloat progress, CGFloat startValue, CGFloat endValue) {
    return startValue + (progress * (endValue - startValue));
}

static CGFloat triggerButtonRadius = 24;
static CGFloat triggerButtonOutlineRadius = 30;
static CGFloat kLayerRadius = 40;
static CGFloat kbottomToolbarHeight = 80;

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (nonnull instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _insets = UIEdgeInsetsMake(16, 16, 16, 16);
    _triggerButtonCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height - triggerButtonOutlineRadius * 2);
    self.tintColor = [UIColor whiteColor];
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    [self addGestureRecognizer:_tapGestureRecognizer];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self.layer addSublayer:self.focusBox];
    [self.layer addSublayer:self.exposeBox];
    [self addSubview:self.shutterView];
    [self addSubview:self.contentView];
    
    [self.contentView addSubview:self.topToolbar];
    [self.contentView addSubview:self.bottomToolbar];
    [self.bottomToolbar addSubview:self.triggerButton];
    [self.bottomToolbar.layer addSublayer:self.triggerButtonOutline];

}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.triggerButton.center = CGPointMake(self.bottomToolbar.bounds.size.width/2, self.bottomToolbar.bounds.size.height/2);
    self.triggerButtonOutline.position = self.triggerButton.center;
}

- (void)setOptimizeProgress:(CGFloat)optimizeProgress
{
    _optimizeProgress = optimizeProgress;
    
    CGFloat opacityFocus = POPTransition(optimizeProgress, 0, 1);
    self.focusBox.opacity = opacityFocus;
    
    CGFloat scaleFocus = POPTransition(optimizeProgress, 2.5, 1);
    self.focusBox.transform = CATransform3DMakeScale(scaleFocus, scaleFocus, 1);
    
    CGFloat rad = POPTransition(optimizeProgress, 0, 1) * M_PI * 2;
    CGFloat opacityExpose = sin(rad)/2 + 0.5;
    self.exposeBox.opacity = opacityExpose;
    
    CGFloat scaleExpose = POPTransition(optimizeProgress, 0.6, 1);
    self.exposeBox.transform = CATransform3DMakeScale(scaleExpose, scaleExpose, 1);
    
}

- (void)setTriggerProgress:(CGFloat)triggerProgress
{
    _triggerProgress = triggerProgress;
    
    CGFloat alpha = POPTransition(triggerProgress, 1, 0);
    self.shutterView.alpha = alpha;
    
    CGFloat triggerAlpha = POPTransition(triggerProgress, 0, 1);
    self.triggerButton.alpha = triggerAlpha;
}

#pragma mark - top toolbar

- (STPCameraViewToolbar *)topToolbar
{
    if (_topToolbar) {
        return _topToolbar;
    }
    _topToolbar = [[STPCameraViewToolbar alloc] initWithFrame:CGRectZero];
    _topToolbar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [_topToolbar setItems:@[self.fixedBarButtonItem, self.flashBarButtonItem, self.flexBarButtonItem, self.devicePositionBarButtonItem,self.fixedBarButtonItem]];
    [_topToolbar sizeToFit];
    return _topToolbar;
}

- (UIBarButtonItem *)flexBarButtonItem
{
    if (_flexBarButtonItem) {
        return _flexBarButtonItem;
    }
    _flexBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    return _flexBarButtonItem;
}

- (UIBarButtonItem *)fixedBarButtonItem
{
    if (_fixedBarButtonItem) {
        return _fixedBarButtonItem;
    }
    _fixedBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    return _fixedBarButtonItem;
}

- (UIBarButtonItem *)flashBarButtonItem
{
    if (_flashBarButtonItem) {
        return _flashBarButtonItem;
    }
    _flashBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Flash" style:UIBarButtonItemStylePlain target:self action:@selector(tapFlashModeBarButtonItem:)];
    return _flashBarButtonItem;
}

- (UIBarButtonItem *)flashOffBarButtonItem
{
    if (_flashOffBarButtonItem) {
        return _flashOffBarButtonItem;
    }
    _flashOffBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Off" style:UIBarButtonItemStylePlain target:self action:@selector(tapFlashModeBarButtonItem:)];
    return _flashOffBarButtonItem;
}

- (UIBarButtonItem *)flashOnBarButtonItem
{
    if (_flashOnBarButtonItem) {
        return _flashOnBarButtonItem;
    }
    _flashOnBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"On" style:UIBarButtonItemStylePlain target:self action:@selector(tapFlashModeBarButtonItem:)];
    return _flashOnBarButtonItem;
}

- (UIBarButtonItem *)flashAutoBarButtonItem
{
    if (_flashAutoBarButtonItem) {
        return _flashAutoBarButtonItem;
    }
    _flashAutoBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Auto" style:UIBarButtonItemStylePlain target:self action:@selector(tapFlashModeBarButtonItem:)];
    return _flashAutoBarButtonItem;
}

- (UIBarButtonItem *)devicePositionBarButtonItem
{
    if (_devicePositionBarButtonItem) {
        return _devicePositionBarButtonItem;
    }
    _devicePositionBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Camera" style:UIBarButtonItemStylePlain target:self action:@selector(tapDevicePostionBarButtonItem:)];
    return _devicePositionBarButtonItem;
}

#pragma mark - element

- (UIView *)bottomToolbar
{
    if (_bottomToolbar) {
        return _bottomToolbar;
    }
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    _bottomToolbar = [[UIView alloc] initWithFrame:CGRectMake(0, screenSize.height - kbottomToolbarHeight, screenSize.width, kbottomToolbarHeight)];
    _bottomToolbar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    return _bottomToolbar;
}

- (UIView *)shutterView
{
    if (_shutterView) {
        return _shutterView;
    }
    _shutterView = [[UIView alloc] initWithFrame:self.bounds];
    _shutterView.backgroundColor = [UIColor blackColor];
    _shutterView.alpha = 0;
    return _shutterView;
}

- (UIView *)contentView
{
    if (_contentView) {
        return _contentView;
    }
    _contentView = [[UIView alloc] initWithFrame:self.bounds];
    _contentView.backgroundColor = [UIColor clearColor];
    return _contentView;
}

#pragma mark - Focus / Expose Box

- (CALayer *)triggerButtonOutline
{
    if (_triggerButtonOutline) {
        return _triggerButtonOutline;
    }
    
    _triggerButtonOutline = [CALayer layer];
    [_triggerButtonOutline setCornerRadius:triggerButtonOutlineRadius];
    [_triggerButtonOutline setBounds:CGRectMake(0.0f, 0.0f, triggerButtonOutlineRadius * 2, triggerButtonOutlineRadius * 2)];
    [_triggerButtonOutline setBorderWidth:5.0f];
    [_triggerButtonOutline setPosition:self.triggerButtonCenter];
    [_triggerButtonOutline setBorderColor:[[UIColor whiteColor] CGColor]];
    
    return _triggerButtonOutline;
}

- (CALayer *)focusBox
{
    if (_focusBox) {
        return _focusBox;
    }
    _focusBox = [CALayer layer];
    [_focusBox setCornerRadius:kLayerRadius];
    [_focusBox setBounds:CGRectMake(0.0f, 0.0f, kLayerRadius * 2, kLayerRadius * 2)];
    [_focusBox setBorderWidth:1.f];
    [_focusBox setBorderColor:[[UIColor whiteColor] CGColor]];
    [_focusBox setPosition:self.center];
    [_focusBox setOpacity:0];
    return _focusBox;
}

- (CALayer *)exposeBox
{
    if (_exposeBox) {
        return _exposeBox;
    }
    _exposeBox = [CALayer layer];
    [_exposeBox setCornerRadius:kLayerRadius];
    [_exposeBox setBounds:CGRectMake(0.0f, 0.0f, kLayerRadius * 2, kLayerRadius * 2)];
    [_exposeBox setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.8].CGColor];
    [_exposeBox setPosition:self.center];
    [_exposeBox setOpacity:0];
    return _exposeBox;
}

#pragma mark - trigger

- (UIView *)triggerButton
{
    if (_triggerButton) {
        return _triggerButton;
    }
    _triggerButton = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, triggerButtonRadius * 2, triggerButtonRadius * 2}];
    _triggerButton.backgroundColor = [UIColor whiteColor];
    [_triggerButton.layer setCornerRadius:triggerButtonRadius];
    [_triggerButton setCenter:self.triggerButtonCenter];
    [_triggerButton addGestureRecognizer:self.triggerTapGestureRecognizer];
    [_triggerButton addGestureRecognizer:self.triggerLongPressGestureRecognizer];
    return _triggerButton;
}

- (UITapGestureRecognizer *)triggerTapGestureRecognizer
{
    if (_triggerTapGestureRecognizer) {
        return _triggerTapGestureRecognizer;
    }
    _triggerTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(triggerTapGesture:)];
    return _triggerTapGestureRecognizer;
}

- (UILongPressGestureRecognizer *)triggerLongPressGestureRecognizer
{
    if (_triggerLongPressGestureRecognizer) {
        return _triggerLongPressGestureRecognizer;
    }
    _triggerLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(triggerLongPressGesture:)];
    return _triggerLongPressGestureRecognizer;
}

#pragma mark - 

- (AVCaptureFlashMode)flashMode
{
    return [self.delegate captureFlashMode];
}

- (AVCaptureDevicePosition)devicePosition
{
    return [self.delegate captureDevicePosition];
}

#pragma mark - trigger action

- (void)triggerTapGesture:(UITapGestureRecognizer *)recognzier
{
    if ([self.delegate respondsToSelector:@selector(cameraViewShouldBeginRecording:)]) {
        if ([self.delegate cameraViewShouldBeginRecording:self]) {
            [self triggerAction:STPCameraModeShot];
        }
    } else {
        [self triggerAction:STPCameraModeShot];
    }
}

- (void)triggerLongPressGesture:(UILongPressGestureRecognizer *)recognizer
{
    if ([self.delegate respondsToSelector:@selector(cameraViewShouldBeginRecording:)]) {
        if ([self.delegate cameraViewShouldBeginRecording:self]) {
            [self triggerAction:STPCameraModeBurst];
        }
    } else {
        [self triggerAction:STPCameraModeBurst];
    }
}

- (void)triggerAction:(STPCameraMode)cameraMode
{
    POPBasicAnimation *animation = [POPBasicAnimation animation];
    animation.duration = 0.25f;
    POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:@"inc.stamp.stp.camera.trigger.property" initializer:^(POPMutableAnimatableProperty *prop) {
        prop.readBlock = ^(id obj, CGFloat values[]) {
            values[0] = [obj triggerProgress];
        };
        prop.writeBlock = ^(id obj, const CGFloat values[]) {
            [obj setTriggerProgress:values[0]];
        };
        prop.threshold = 0.01;
    }];
    animation.property = prop;
    animation.fromValue = @(0);
    animation.toValue = @(1);
    [self pop_addAnimation:animation forKey:@"inc.stamp.stp.camera.trigger"];
    if ([self.delegate respondsToSelector:@selector(cameraViewStartRecording:)]) {
        [self.delegate cameraViewStartRecording:cameraMode];
    }
}

#pragma mark - optimize action

- (void)tapGesture:(UITapGestureRecognizer *)recognizer
{
    if ([self.delegate respondsToSelector:@selector(cameraViewShouldBeginOptimize:)]) {
        if ([self.delegate cameraViewShouldBeginOptimize:self]) {
            CGPoint point = [recognizer locationInView:self];
            [self drawAtPoint:point remove:YES];
            [self.delegate cameraView:self optimizeAtPoint:point];
        }
    } else {
        CGPoint point = [recognizer locationInView:self];
        [self drawAtPoint:point remove:YES];
        [self.delegate cameraView:self optimizeAtPoint:point];
    }
}

#pragma mark - change capture device action

- (void)tapDevicePostionBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    if ([self.delegate respondsToSelector:@selector(cameraViewShouldChangeCaptureDevicePosition:)]) {
        if ([self.delegate cameraViewShouldChangeCaptureDevicePosition:self]) {
            [self changeCaptureDevicePosition];
        }
    } else {
        [self changeCaptureDevicePosition];
    }
}

- (void)changeCaptureDevicePosition
{
    if (self.devicePosition == AVCaptureDevicePositionBack) {
        [self.delegate cameraView:self changeCaptureDevicePosition:AVCaptureDevicePositionFront];
    } else if (self.devicePosition == AVCaptureDevicePositionFront) {
        [self.delegate cameraView:self changeCaptureDevicePosition:AVCaptureDevicePositionBack];
    }
}

#pragma mark - change capture flash mode action

- (void)tapFlashModeBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    if (barButtonItem == self.flashBarButtonItem) {
        [self.topToolbar setItems:@[self.flexBarButtonItem,
                                    self.flashAutoBarButtonItem,
                                    self.flexBarButtonItem,
                                    self.flashOnBarButtonItem,
                                    self.flexBarButtonItem,
                                    self.flashOffBarButtonItem,
                                    self.flexBarButtonItem] animated:YES];
    } else {
        if ([self.delegate respondsToSelector:@selector(cameraViewShouldChangeCaptureFlashMode:)]) {
            if ([self.delegate cameraViewShouldChangeCaptureFlashMode:self]) {
                [self changeFlashMode:barButtonItem];
            }
        } else {
            [self changeFlashMode:barButtonItem];
        }
        [self.topToolbar setItems:@[self.fixedBarButtonItem, self.flashBarButtonItem, self.flexBarButtonItem, self.devicePositionBarButtonItem, self.fixedBarButtonItem] animated:YES];
    }
}

- (void)changeFlashMode:(UIBarButtonItem *)barButtonItem
{
    AVCaptureFlashMode captureFlashMode;

    if (barButtonItem == self.flashOnBarButtonItem) {
        captureFlashMode = AVCaptureFlashModeOn;
    } else if (barButtonItem == self.flashOffBarButtonItem) {
        captureFlashMode = AVCaptureFlashModeOff;
    } else {
        captureFlashMode = AVCaptureFlashModeAuto;
    }
    
    [self.delegate cameraView:self changeCaptureFlashMode:captureFlashMode];
}

#pragma mark -

- (void)drawAtPoint:(CGPoint)point remove:(BOOL)remove
{
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    [self.focusBox setPosition:point];
    [self.exposeBox setPosition:point];
    [CATransaction commit];
    if (remove) {
        [self.focusBox pop_removeAllAnimations];
        [self.exposeBox pop_removeAllAnimations];
    }
    
    POPBasicAnimation *animation = [POPBasicAnimation animation];
    POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:@"inc.stamp.stp.camera.optimize.property" initializer:^(POPMutableAnimatableProperty *prop) {
        prop.readBlock = ^(id obj, CGFloat values[]) {
            values[0] = [obj optimizeProgress];
        };
        prop.writeBlock = ^(id obj, const CGFloat values[]) {
            [obj setOptimizeProgress:values[0]];
        };
        prop.threshold = 0.01;
    }];
    animation.duration = 0.65f;
    animation.property = prop;
    animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        
        if (finished) {
            POPBasicAnimation *animation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
            animation.duration = 0.55f;
            animation.toValue = @(0);
            [self.focusBox pop_addAnimation:animation forKey:@"inc.stamp.camera.focus.opacity"];
            [self.exposeBox pop_addAnimation:animation forKey:@"inc.stamp.camera.expose.opacity"];
        }
        
    };
    animation.fromValue = @(0);
    animation.toValue = @(1);
    [self pop_addAnimation:animation forKey:@"inc.stamp.stp.camera.optimize"];
    
}

@end
