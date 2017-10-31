//
//  AMRefreshView.m
//  AMWebBrowser
//
//  Created by AndyMu on 2017/10/30.
//  Copyright © 2017年 AndyMu. All rights reserved.
//

#import "AMRefreshView.h"

@implementation AMRefreshView

- (void)layoutSubviews {
    [super layoutSubviews];
    [self customView];
}

- (void)customView {
    self.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon_loadfail"]];
    [imageView setFrame:CGRectMake((self.frame.size.width - 74)/2, 200, 74, 74)];
    [self addSubview:imageView];

    UILabel *reminderLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 300, self.frame.size.width, 50)];
    reminderLabel.text = @"页面加载失败，点击重新加载";
    reminderLabel.textColor = [UIColor redColor];
    reminderLabel.font = [UIFont systemFontOfSize:15];
    reminderLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:reminderLabel];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_block) { _block();}
}

@end
