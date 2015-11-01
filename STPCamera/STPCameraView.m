//
//  STPCameraView.m
//  STPCamera
//
//  Created by 1amageek on 2015/10/30.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import "STPCameraView.h"

@interface STPCameraView ()

@property (nonatomic) UIEdgeInsets insets;

@property (nonatomic) CGPoint triggerButtonCenter;

@property (nonatomic) UIButton *triggerButton;
@property (nonatomic) UIButton *cancelButton;
@property (nonatomic) UIButton *cameraButton;
@property (nonatomic) UIButton *flashButton;

@property (nonatomic) CALayer *triggerButtonOutline;
@property (nonatomic) CALayer *focusBox;
@property (nonatomic) CALayer *exposeBox;

@property (nonatomic) UIView *upperToolbar;
@property (nonatomic) UIView *underToolbar;
@property (nonatomic) UIView *contentView;
@property (nonatomic) UIView *shutterView;

@property (nonatomic) CGFloat optimizeProgress;
@property (nonatomic) CGFloat triggerProgress;

@property (nonatomic) AVCaptureFlashMode flashMode;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation STPCameraView
static inline CGFloat POPTransition(CGFloat progress, CGFloat startValue, CGFloat endValue) {
    return startValue + (progress * (endValue - startValue));
}

static CGFloat triggerButtonRadius = 24;
static CGFloat triggerButtonOutlineRadius = 30;
static CGFloat kLayerRadius = 40;
static CGFloat kUpperToolbarHeight = 40;
static CGFloat kUnderToolbarHeight = 100;

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
    _flashMode = AVCaptureFlashModeAuto;
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
    
    [self.contentView addSubview:self.upperToolbar];
    [self.upperToolbar addSubview:self.flashButton];
    [self.upperToolbar addSubview:self.cameraButton];
    
    [self.contentView addSubview:self.underToolbar];
    [self.underToolbar addSubview:self.cancelButton];
    [self.underToolbar addSubview:self.triggerButton];
    [self.underToolbar.layer addSublayer:self.triggerButtonOutline];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.flashButton.center = CGPointMake(self.insets.left + self.flashButton.bounds.size.width/2, self.upperToolbar.center.y);
    self.cameraButton.center = CGPointMake(self.bounds.size.width - self.cameraButton.bounds.size.width/2 - self.insets.right, self.upperToolbar.center.y);
    
    self.triggerButton.center = CGPointMake(self.underToolbar.bounds.size.width/2, self.underToolbar.bounds.size.height/2);
    self.triggerButtonOutline.position = self.triggerButton.center;
    self.cancelButton.center = CGPointMake(self.bounds.size.width - self.cancelButton.bounds.size.width, self.triggerButton.center.y);
    
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

#pragma mark - element

- (UIView *)upperToolbar
{
    if (_upperToolbar) {
        return _upperToolbar;
    }
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    _upperToolbar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, kUpperToolbarHeight)];
    _upperToolbar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    return _upperToolbar;
}

- (UIView *)underToolbar
{
    if (_underToolbar) {
        return _underToolbar;
    }
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    _underToolbar = [[UIView alloc] initWithFrame:CGRectMake(0, screenSize.height - kUnderToolbarHeight, screenSize.width, kUnderToolbarHeight)];
    _underToolbar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    return _underToolbar;
}

- (UIButton *)triggerButton
{
    if (_triggerButton) {
        return _triggerButton;
    }
    _triggerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_triggerButton setBackgroundColor:self.tintColor];
    [_triggerButton setFrame:(CGRect){ 0, 0, triggerButtonRadius * 2, triggerButtonRadius * 2}];
    [_triggerButton.layer setCornerRadius:triggerButtonRadius];
    [_triggerButton setCenter:self.triggerButtonCenter];
    [_triggerButton addTarget:self action:@selector(triggerAction:) forControlEvents:UIControlEventTouchUpInside];
    return _triggerButton;
}

- (UIButton *)cameraButton
{
    if (_cameraButton) {
        return _cameraButton;
    }
    _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_cameraButton setTitle:@"Camera" forState:UIControlStateNormal];
    [_cameraButton addTarget:self action:@selector(tapCameraButton:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraButton sizeToFit];
    return _cameraButton;
}

- (UIButton *)flashButton
{
    if (_flashButton) {
        return _flashButton;
    }
    _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_flashButton setTitle:@"Flash auto" forState:UIControlStateNormal];
    [_flashButton addTarget:self action:@selector(tapFlashButton:) forControlEvents:UIControlEventTouchUpInside];
    [_flashButton sizeToFit];
    return _flashButton;
}

- (UIButton *)cancelButton
{
    if (_cancelButton) {
        return _cancelButton;
    }
    _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_cancelButton addTarget:self action:@selector(tapCancelButton:) forControlEvents:UIControlEventTouchUpInside];
    [_cancelButton setTitle:@"キャンセル" forState:UIControlStateNormal];
    [_cancelButton sizeToFit];
    return _cancelButton;
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

#pragma mark - action

- (void)tapCameraButton:(UIButton *)button
{
    [self.delegate changeCamera];
}

- (void)tapFlashButton:(UIButton *)button
{
    switch (self.flashMode) {
        case AVCaptureFlashModeAuto:
            self.flashMode = AVCaptureFlashModeOn;
            [self.flashButton setTitle:@"Flash on" forState:UIControlStateNormal];
            break;
        case AVCaptureFlashModeOn:
            self.flashMode = AVCaptureFlashModeOff;
            [self.flashButton setTitle:@"Flash off" forState:UIControlStateNormal];
            break;
        case AVCaptureFlashModeOff:
            self.flashMode = AVCaptureFlashModeAuto;
            [self.flashButton setTitle:@"Flash auto" forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
    [self.delegate flashMode:self.flashMode];
}

- (void)tapCancelButton:(UIButton *)button
{
    [self.delegate cancel];
}

- (void)tapGesture:(UITapGestureRecognizer *)recognizer
{
    [self drawAtPoint:[recognizer locationInView:self] remove:YES];
    if ([self.delegate respondsToSelector:@selector(cameraView:optimizeAtPoint:)]) {
        [self.delegate cameraView:self optimizeAtPoint:[recognizer locationInView:self]];
    }
}

- (void)triggerAction:(UIButton *)button
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
    if ([self.delegate respondsToSelector:@selector(cameraViewStartRecording)]) {
        [self.delegate cameraViewStartRecording];
    }
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


@end
