//
//  MyScrollView.m
//  CustomScrollView
//
//  Created by binluo on 2017/5/15.
//  Copyright © 2017年 baijiahulian. All rights reserved.
//

#import "MyScrollView.h"

static const CGFloat acceleration = 0.450f;

typedef void (^ScrollCompletionBlock)(BOOL finished);

@interface MyScrollView ()

@property (nonatomic, assign) CGPoint startPoint;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, copy) ScrollCompletionBlock scrollCompletion;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) CGPoint startContentOffset;
@property (nonatomic, assign) CGPoint startVelocity;
@property (nonatomic, assign) CGFloat acceleration;
@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, assign) CGFloat targetOffsetY;

@property (nonatomic, assign) BOOL runLoopIsRunning;

@end

@implementation MyScrollView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerAction:)];
        [self addGestureRecognizer:panGestureRecognizer];
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if (self.displayLink) {
        [self stopDisplayLink];
        if (self.scrollCompletion) {
            ScrollCompletionBlock precompletion = self.scrollCompletion;
            self.scrollCompletion = nil;
            precompletion(NO);
        }
    }
    if (self.runLoopIsRunning) {
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
    self.runLoopIsRunning = YES;
    CFRunLoopRunInMode((CFRunLoopMode)UITrackingRunLoopMode, DISPATCH_TIME_FOREVER, NO);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (self.runLoopIsRunning) {
        CFRunLoopStop(CFRunLoopGetCurrent());
        self.runLoopIsRunning = NO;
    }
}

#pragma mark - Action
- (void)panGestureRecognizerAction:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.startPoint = self.contentOffset;
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [panGestureRecognizer translationInView:self];
        CGPoint targetPoint = CGPointMake(self.startPoint.x + translation.x, self.startPoint.y + translation.y);
        [self setContentOffset:targetPoint bounce:NO animated:NO];
        
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (self.runLoopIsRunning) {
            CFRunLoopStop(CFRunLoopGetCurrent());
            self.runLoopIsRunning = NO;
        }
        
        self.startPoint = CGPointZero;
        
        CGPoint velocity = [panGestureRecognizer velocityInView:self];
        
        //已超出边界，回弹
        if ([self contentScrollBeyondBounds]) {
            [self bounceBack];
        } else {
            if (fabs(velocity.y) > 300) {
                CGFloat duration = 1.5;
                //加速度跟速度的方向相反，做减速运动
                CGFloat acceleration = -(velocity.y)/duration;
                //移动距离 s = vt + 1/2*a*t^2
                CGFloat targetOffsetY = velocity.y * duration + acceleration * duration * duration/2 + self.contentOffset.y;
                CGFloat height = self.bounds.size.height;
                NSLog(@"targetOffsetY:%f", targetOffsetY);
                if (self.contentSize.height < height || targetOffsetY > 0) {
                    //目标contentOff超出上边，有一个小幅度回弹效果
                    [self bounceTop:velocity.y acceleration:acceleration];
                } else if (-targetOffsetY > self.contentSize.height - height) {
                    //目标contentOff超出下边，有一个小幅度回弹效果，暂未实现
                    [self smoothScroll:duration startVelocity:velocity.y acceleration:acceleration completion:nil];
                } else {
                    [self smoothScroll:duration startVelocity:velocity.y acceleration:acceleration completion:nil];
                }
            }
        }
    }
}

#pragma mark - Private
-(void)updateContentOffset {
    if (!self.displayLink || self.displayLink.paused) {
        return;
    }
    CGFloat currentDudation = CACurrentMediaTime() - self.startTime;
    //如果已经超出时间，立即停止
    BOOL shouldStop = NO;
    if (currentDudation > self.duration) {
        currentDudation = self.duration;
        [self stopDisplayLink];
        shouldStop = YES;
    }
    
    //移动距离 s = vt + 1/2*a*t^2
    CGFloat currentOffsetY = self.startVelocity.y * currentDudation + self.acceleration * currentDudation * currentDudation/2 + self.startContentOffset.y;
    
    CGPoint contentOffset = self.contentOffset;
    contentOffset.y = currentOffsetY;
    [self setContentOffset:contentOffset bounce:NO animated:NO];
    
    if (shouldStop) {
        if (self.scrollCompletion) {
            ScrollCompletionBlock precompletion = self.scrollCompletion;
            self.scrollCompletion = nil;
            precompletion(YES);
        }
    }
}

- (void)smoothScroll:(CGFloat)duration startVelocity:(CGFloat)startVelocity acceleration:(CGFloat)acceleration completion:(ScrollCompletionBlock)completion {
    if (self.displayLink) {
        [self stopDisplayLink];
        if (self.scrollCompletion) {
            ScrollCompletionBlock precompletion = self.scrollCompletion;
            self.scrollCompletion = nil;
            precompletion(NO);
        }
    }
    
    self.scrollCompletion = completion;
    self.acceleration = acceleration;
    //        s = vt + 1/2*a*t^2
    self.startVelocity = CGPointMake(0, startVelocity);
    self.duration = duration;
    self.startContentOffset = self.contentOffset;
    [self startDisplayLink];
}

- (void)startDisplayLink{
    self.startTime = CACurrentMediaTime();
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateContentOffset)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopDisplayLink{
    self.displayLink.paused = YES;
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)setContentOffset:(CGPoint)contentOffset bounce:(BOOL)bounce animated:(BOOL)animated {
    CGRect bounds = self.bounds;
    bounds.origin.y = - contentOffset.y;
    if (bounce) {
        if (bounds.origin.y < 0) {
            bounds.origin.y = 0;
        }
        CGFloat height = self.bounds.size.height;
        if (self.contentSize.height < height) {
            bounds.origin.y = 0;
        } else if (bounds.origin.y > self.contentSize.height - self.bounds.size.height) {
            bounds.origin.y = self.contentSize.height - self.bounds.size.height;
        }
    }
    self.bounds = bounds;
}

//内容是否滑动超出bounds
- (BOOL)contentScrollBeyondBounds {
    CGFloat height = self.bounds.size.height;
    if (self.contentSize.height < height || self.contentOffset.y > 0) {
        return YES;
    } else if (-self.contentOffset.y > self.contentSize.height - height) {
        return YES;
    }
    return NO;
}

- (void)bounceTop:(CGFloat)velocity acceleration:(CGFloat)acceleration {
    CGFloat distance = fabs(self.contentOffset.y);
    //由s = vt + 1/2*a*t^2及a = -v/1.5，反推出t ==> 3s/v = 3t - t^2，解方程
    CGFloat duration = 1.5 - sqrt( 9.0/4 - 3 * distance /velocity);
    //滑动到contentOffset为0的地方
    [self smoothScroll:duration startVelocity:velocity acceleration:acceleration completion:^(BOOL finished) {
        //小幅弹出
        if (finished) {
            [self smoothScroll:0.2 startVelocity:300.f acceleration:0 completion:^(BOOL finished) {
                if (finished) {
                    //小幅弹回
                    [self smoothScroll:0.2 startVelocity:-300.f acceleration:0 completion:^(BOOL finished) {
                        if (finished) {
                            CGPoint contentOffset = self.contentOffset;
                            contentOffset.y = 0;
                            [self setContentOffset:contentOffset bounce:NO animated:NO];
                        }
                    }];
                }
            }];
        }
    }];
}

- (void)bounceBack {
    CGFloat height = self.bounds.size.height;
    if (self.contentSize.height < height || self.contentOffset.y > 0) {
        CGFloat time = 0.25;
        CGFloat distance = self.contentOffset.y;
        //做匀速运动
        CGFloat acceleration = 0;
        [self smoothScroll:time startVelocity:-(distance/time) acceleration:acceleration completion:^(BOOL finished) {
            if (finished) {
                CGPoint contentOffset = self.contentOffset;
                contentOffset.y = 0;
                [self setContentOffset:contentOffset bounce:NO animated:NO];
            }
        }];
    } else if (-self.contentOffset.y > self.contentSize.height - height) {
        
        CGFloat time = 0.25;
        CGFloat distance =-self.contentOffset.y - (self.contentSize.height - height);
        //做匀速运动
        CGFloat acceleration = 0;
        [self smoothScroll:time startVelocity:distance/time acceleration:acceleration completion:^(BOOL finished) {
            if (finished) {
                CGPoint contentOffset = self.contentOffset;
                contentOffset.y = self.contentSize.height - height;
                [self setContentOffset:contentOffset bounce:NO animated:NO];
            }
        }];
    }
}

#pragma mark - Public
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    [self setContentOffset:contentOffset bounce:YES animated:animated];
}

#pragma mark - Getter & Setter
- (void)setContentOffset:(CGPoint)contentOffset {
    CGRect bounds = self.bounds;
    bounds.origin.y = - contentOffset.y;
    self.bounds = bounds;
}

- (CGPoint)contentOffset {
    CGRect bounds = self.bounds;
    return CGPointMake(-bounds.origin.x, -bounds.origin.y);
}

@end
