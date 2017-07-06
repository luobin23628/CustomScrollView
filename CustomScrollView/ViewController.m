//
//  ViewController.m
//  CustomScrollView
//
//  Created by binluo on 2017/5/15.
//  Copyright © 2017年 baijiahulian. All rights reserved.
//

#import "ViewController.h"
#import "MyScrollView.h"

@interface ViewController ()<UIScrollViewDelegate>

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

//    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
//    scrollView.delegate = self;
    
    MyScrollView *scrollView = [[MyScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:scrollView];
    
    CGFloat y = 0, screenHeight = 2000;
    NSInteger i = 0;
    while (y < screenHeight) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 200, 20)];
        label.text = [NSString stringWithFormat:@"%ld", i];
        [scrollView addSubview:label];
        y += 30;
        i++;
    }
    [scrollView setContentSize:CGSizeMake(200, 2000)];
    
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^(NSTimer * _Nonnull timer) {
//        NSLog(@"测试");
//    }];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"%@", NSStringFromCGRect(scrollView.bounds));
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSLog(@"scrollViewWillEndDragging ==== velocity:%@, targetContentOffset:%@", NSStringFromCGPoint(velocity), NSStringFromCGPoint(*targetContentOffset));
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

@end
