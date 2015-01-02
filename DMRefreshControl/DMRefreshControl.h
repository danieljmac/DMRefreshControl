//
//  DMRefreshControl.h
//  Perq
//
//  Created by Daniel McCarthy on 1/18/14.
//  Copyright (c) 2014 Daniel McCarthy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DMRefreshControl : UIView {
    
}

@property (strong, nonatomic) UIColor *controlColor;
@property (assign, nonatomic) CGFloat backgroundAlpha;
@property (strong, nonatomic) UIView *circle1;
@property (strong, nonatomic) UIView *circle2;
@property (strong, nonatomic) UIView *opaqueBackground;
@property (strong, nonatomic) UILabel *refreshLabel;
@property (assign, nonatomic) BOOL isRefreshing;
@property (nonatomic, copy) void (^refreshCalledHandler)(void);
@property (assign, nonatomic) CGPoint circleCenter;

- (id)initWithColor:(UIColor *)color inScrollView:(UIScrollView *)scrollView;
- (void)addRefreshControlToViewController:(UIViewController *)viewController forScrollViews:(NSArray *)scrollViews;
- (void)addAdditionalScrollViewObserver:(UIScrollView *)scrollView;
- (void)addCalledForRefreshHandler:(void (^)(void))actionHandler;
- (void)stopRefreshing;
- (void)updateControlForOrientationChangeWithViewFrameSize:(CGSize)size andCenterX:(CGFloat)centerX;
@end
