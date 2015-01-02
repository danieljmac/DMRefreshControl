//
//  DMRefreshControl.m
//  Perq
//
//  Created by Daniel McCarthy on 1/18/14.
//  Copyright (c) 2014 Daniel McCarthy. All rights reserved.
//

#import "DMRefreshControl.h"
#import <QuartzCore/QuartzCore.h>

@interface DMRefreshControl () <UIScrollViewDelegate> {
    CGFloat initialDiameter;
    CGFloat pulsingCircleDiameter;
    CGFloat maxDiameter;
    CGFloat minDiameter;
    CGFloat itemCenterFromBottom;
    CGFloat borderWidth;
    CGFloat controlHeight;
    CGFloat controlWidth;
    CGFloat controlOffsetY;
    CGFloat threshHoldBegin;
    CGFloat threshHoldCutoff;
    CGRect pullDownRect;
    CGPoint lastDraggingOffset;
    CGFloat originalContentInsetTop;
    CGFloat refreshingHeight;
    
    BOOL isPulledEnoughToRefresh;
    BOOL isReadyPulsing;
    BOOL isPulseCircleAtMin;
    BOOL shouldCallRefresh;
}

@property (strong, nonatomic) NSMutableArray *observerScrollViews;
@property (strong, nonatomic) CABasicAnimation *pulseAnimation;
@property (strong, nonatomic) CAAnimationGroup *sonarAnimation;

@end

@implementation DMRefreshControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithColor:(UIColor *)color inScrollView:(UIScrollView *)scrollView {
    self = [super init];
    if (self) {
        [self setInitialValues];
        self.frame = pullDownRect;
        self.backgroundColor = [UIColor clearColor];
        self.controlColor = color;
        [self setupTheViews];
    }
    return self;
}

- (void)addRefreshControlToViewController:(UIViewController *)viewController forScrollViews:(NSArray *)scrollViews {
    self.observerScrollViews = [scrollViews mutableCopy];
    for (UIScrollView *scrollView in self.observerScrollViews) {
        originalContentInsetTop = scrollView.contentInset.top;
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
        [scrollView addObserver:self forKeyPath:@"pan.state" options:NSKeyValueObservingOptionNew context:nil];
    }
    [viewController.view insertSubview:self atIndex:1000];
}

- (void)addAdditionalScrollViewObserver:(UIScrollView *)scrollView {
    [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    [scrollView addObserver:self forKeyPath:@"pan.state" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        CGPoint offset = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
        CGPoint oldOffset = [[change objectForKey:NSKeyValueChangeOldKey] CGPointValue];
        lastDraggingOffset = offset;
        [self didScrollWithOffset:offset andOldOffset:oldOffset];
        if (shouldCallRefresh == YES) {
           //NSLog(@"oldOffset: %f",oldOffset.y);
           //NSLog(@"lastdragging: %f",lastDraggingOffset.y);
            if (oldOffset.y <= lastDraggingOffset.y) {
                shouldCallRefresh = NO;
                [self handleRefreshReleased];
               //NSLog(@"handle refresh released");
            }
        }
    }
    else if ([keyPath isEqualToString:@"pan.state"]) {
        if ([object isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = object;
            if (scrollView.panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
                if (lastDraggingOffset.y <= 0) {
                    shouldCallRefresh = YES;
                   //NSLog(@"should call refresh");
                }
            }
        }
    }
}

#pragma Scrollview Delegate Methods

- (void)didScrollWithOffset:(CGPoint)offSet andOldOffset:(CGPoint)oldOffset {
    CGFloat offsetY = offSet.y;
    if (self.isRefreshing == NO) {
        if (offsetY < threshHoldCutoff || oldOffset.y < threshHoldCutoff) {
            isPulledEnoughToRefresh = YES;
            if (isReadyPulsing == NO) {
                isReadyPulsing = YES;
                [self animateCircleOutForPulse:self.circle2];
            }
        }
        else if(offsetY <= 0.0f) {
            isPulledEnoughToRefresh = NO;
            if (isReadyPulsing == YES) {
                isReadyPulsing = NO;
                [self animatePulsingCircleBackIn:self.circle2];
            }
        }
        
        if (offsetY <= threshHoldBegin) {
            CGFloat scaleFactor = (offsetY - threshHoldBegin)*0.2f;
            [self changeOuterCircleSizeBasedOnOffset:offsetY byScaleFactor:scaleFactor];
        }
    }
    
    //move the entire controls view
    if (offsetY <= 0.0f) {
        CGFloat posOffset = offsetY * -1;
        CGFloat pulldownOffset = posOffset + pullDownRect.origin.y;
        self.frame = CGRectMake(self.frame.origin.x, pulldownOffset, self.frame.size.width, self.frame.size.height);
    }
    else {
        if (self.frame.origin.y != pullDownRect.origin.y)
            self.frame = pullDownRect;
    }
}

#pragma mark - SetupMethods
- (void)setInitialValues {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    self.isRefreshing = NO;
    isReadyPulsing = NO;
    isPulseCircleAtMin = YES;
    controlHeight = 400.0f;
    controlWidth = width;
    controlOffsetY = controlHeight * -1;
    initialDiameter = 6.0f;
    pulsingCircleDiameter = 30.0f;
    maxDiameter = 44.0f;
    minDiameter = 5.0f;
    itemCenterFromBottom = 40.0f;
    borderWidth = 3.0f;
    threshHoldBegin = -20.0f;
    threshHoldCutoff = -85.0f;
    refreshingHeight = 70.0f;
    self.circleCenter = CGPointMake(width/2, controlHeight-itemCenterFromBottom);
    pullDownRect = CGRectMake(0, controlOffsetY, controlWidth, controlHeight);
    self.backgroundAlpha = 0.5f;
    self.observerScrollViews = [NSMutableArray new];
    self.pulseAnimation = [self thePulsingAnimation];
    self.sonarAnimation = [self theSonarAnimation];
}

- (void)setupTheViews {
    self.opaqueBackground = [self theBackgroundView];
    [self addSubview:self.opaqueBackground];
    self.refreshLabel = [self theRefreshLabel];
    self.circle1 = [self theCircleView];
    self.circle2 = [self theCircleView];
    self.circle1.center = self.circleCenter;
    self.circle2.center = self.circleCenter;
    [self addSubview:self.circle1];
    [self addSubview:self.circle2];
}

- (UIView *)theCircleView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, minDiameter, minDiameter)];
    view.backgroundColor = [UIColor clearColor];
    view.layer.cornerRadius = view.frame.size.width/2;
    view.layer.borderColor = self.controlColor.CGColor;
    view.layer.borderWidth = borderWidth;
    view.layer.masksToBounds = YES;
    return view;
}

- (UIView *)theBackgroundView {
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, controlWidth, controlHeight)];
    bgView.backgroundColor = [UIColor blackColor];
    bgView.alpha = self.backgroundAlpha;
    return bgView;
}

- (UILabel *)theRefreshLabel {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(100, 0, 150, 40)];
    lbl.center = CGPointMake(lbl.center.x, self.frame.size.height-itemCenterFromBottom);
    lbl.backgroundColor = [UIColor clearColor];
    lbl.font = [UIFont systemFontOfSize:12.0f];
    lbl.textColor = [UIColor whiteColor];
    lbl.text = @"Pull to refresh.";
    return lbl;
}

- (CABasicAnimation *)thePulsingAnimation {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.duration = 0.1;
    animation.repeatCount = HUGE_VAL;
    animation.autoreverses = YES;
    animation.fromValue = [NSNumber numberWithFloat:1.0f];
    animation.toValue = [NSNumber numberWithFloat:0.8f];
    return animation;
}

- (CAAnimationGroup *)theSonarAnimation {
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    scaleAnimation.toValue = [NSNumber numberWithFloat:1.0f];
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = [NSNumber numberWithFloat:1.0f];
    alphaAnimation.toValue = [NSNumber numberWithFloat:0.0f];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = 0.8;
    group.repeatCount = HUGE_VAL;
    group.autoreverses = NO;
    group.animations = [NSArray arrayWithObjects:scaleAnimation, alphaAnimation, nil];
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    return group;
}

#pragma PropertyDefinitionMethods

- (void)setBackgroundAlpha:(CGFloat)backgroundAlpha {
    _backgroundAlpha = backgroundAlpha;
    if (self.opaqueBackground)
        self.opaqueBackground.alpha = _backgroundAlpha;
}

#pragma Functionality Methods

- (void)changeOuterCircleSizeBasedOnOffset:(CGFloat)offset byScaleFactor:(CGFloat)scaleFactor {
    CGFloat size;
    if (scaleFactor == 0)
        size = minDiameter;
    else
        size = minDiameter * scaleFactor;
    [self adjustSizeOfCircle:self.circle1 toSize:size];
}

- (void)animateCircleOutForPulse:(UIView *)circle {
    //isReadyPulsing = YES;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        circle.layer.affineTransform = CGAffineTransformMakeScale(7.0f, 7.0f);
    } completion:^(BOOL finished) {
        circle.layer.affineTransform = CGAffineTransformMakeScale(1.0f, 1.0f);
        [self adjustSizeOfCircle:circle toSize:pulsingCircleDiameter];
        [self addThePulseAnimationToTheCircle:circle];
    }];
}

- (void)animatePulsingCircleBackIn:(UIView *)circle {
    //isReadyPulsing = NO;
    [self removeThePulseAnimationFromTherCircle:circle];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        circle.layer.affineTransform = CGAffineTransformMakeScale(0.1f, 0.1f);
    } completion:^(BOOL finished) {
        circle.layer.affineTransform = CGAffineTransformMakeScale(1.0f, 1.0f);
        [self adjustSizeOfCircle:circle toSize:minDiameter];
    }];
}

- (void)addThePulseAnimationToTheCircle:(UIView *)circle {
    [circle.layer addAnimation:self.pulseAnimation forKey:@"scale"];
}

- (void)removeThePulseAnimationFromTherCircle:(UIView *)circle {
    [circle.layer removeAnimationForKey:@"scale"];
}

- (void)addTheSonarAnimationToTheCircle:(UIView *)circle {
    [circle.layer addAnimation:self.sonarAnimation forKey:@"opacity"];
}

- (void)removeTheSonarAnimationFromTherCircle:(UIView *)circle {
    [circle.layer removeAnimationForKey:@"opacity"];
}

- (void)adjustSizeOfCircle:(UIView *)circle toSize:(CGFloat)size {
    circle.frame = CGRectMake(0, 0, size, size);
    circle.center = self.circleCenter;
    circle.layer.cornerRadius = circle.frame.size.width/2;
    circle.layer.masksToBounds = YES;
}

#pragma mark - Action Methods

- (void)handleRefreshReleased {
    if (isPulledEnoughToRefresh == YES) {
       //NSLog(@"1");
        if (self.isRefreshing == NO) {
           //NSLog(@"2");
            //start refreshing
            self.isRefreshing = YES;
            for (UIScrollView *scrollView in self.observerScrollViews) {
                /*[UIView animateWithDuration:0.2
                                      delay:0
                                    options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                                 animations:^{
                                     scrollView.contentOffset = CGPointMake(0, -refreshingHeight-originalContentInsetTop);
                                     scrollView.contentInset = UIEdgeInsetsMake(refreshingHeight+originalContentInsetTop, 0.0f, 0.0f, 0.0f);
                                 }
                                 completion:^(BOOL finished) {
                                     
                                 }];*/
                //[self performSelector:@selector(adjustContentDownInScrollview:) withObject:scrollView afterDelay:0.0];
                [UIView beginAnimations:nil context:NULL];
                [UIView setAnimationDuration:0.2];
                scrollView.contentInset = UIEdgeInsetsMake(refreshingHeight+originalContentInsetTop, 0.0f, 0.0f, 0.0f);
                scrollView.contentOffset = CGPointMake(0, -refreshingHeight-originalContentInsetTop);
                [UIView commitAnimations];
                
                [self addTheSonarAnimationToTheCircle:self.circle1];
                [self animatePulsingCircleBackIn:self.circle2];
                if (self.refreshCalledHandler) {
                    self.refreshCalledHandler();
                }
                
            }
        }
    }
    else {
        [self removeTheSonarAnimationFromTherCircle:self.circle1];
        [self removeTheSonarAnimationFromTherCircle:self.circle2];
        [self removeThePulseAnimationFromTherCircle:self.circle1];
        [self removeThePulseAnimationFromTherCircle:self.circle2];
    }
}

- (void)stopRefreshing {
    [self didEndRefreshing];
}

- (void)didEndRefreshing {
    [self adjustSizeOfCircle:self.circle1 toSize:minDiameter];
    [self adjustSizeOfCircle:self.circle2 toSize:minDiameter];
    [self removeTheSonarAnimationFromTherCircle:self.circle1];
    [self removeTheSonarAnimationFromTherCircle:self.circle2];
    [self removeThePulseAnimationFromTherCircle:self.circle1];
    [self removeThePulseAnimationFromTherCircle:self.circle2];
    for (UIScrollView *scrollView in self.observerScrollViews) {
        /*[UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             scrollView.contentOffset = CGPointMake(0, 0);
                             scrollView.contentInset = UIEdgeInsetsMake(originalContentInsetTop, 0.0f, 0.0f, 0.0f);
                             //Also here we need to animate the 2 circles back to starting position
                         }
                         completion:^(BOOL finished) {
                             self.isRefreshing = NO;
                             [self adjustSizeOfCircle:self.circle1 toSize:minDiameter];
                             [self adjustSizeOfCircle:self.circle2 toSize:minDiameter];
                         }];*/
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2];
        scrollView.contentInset = UIEdgeInsetsMake(originalContentInsetTop, 0.0f, 0.0f, 0.0f);
        scrollView.contentOffset = CGPointMake(0, 0);
        [UIView commitAnimations];
        
        self.isRefreshing = NO;
        
    }
}

- (void)addCalledForRefreshHandler:(void (^)(void))actionHandler {
    self.refreshCalledHandler = actionHandler;
}

- (void)dealloc {
    for (id scrollView in self.observerScrollViews) {
        [scrollView removeObserver:self forKeyPath:@"contentOffset"];
        [scrollView removeObserver:self forKeyPath:@"pan.state"];
    }
}

- (void)updateControlForOrientationChangeWithViewFrameSize:(CGSize)size andCenterX:(CGFloat)centerX {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, size.width, self.frame.size.height);
    self.opaqueBackground.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.circleCenter = CGPointMake(centerX, self.circleCenter.y);
    self.circle1.center = self.circleCenter;
    self.circle2.center = self.circleCenter;
}

@end
