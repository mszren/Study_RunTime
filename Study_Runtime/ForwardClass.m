//
//  ForwardClass.m
//  Study_Runtime
//
//  Created by rytong on 2017/6/8.
//  Copyright © 2017年 rytong. All rights reserved.
//

#import "ForwardClass.h"

@implementation ForwardClass 

- (void)doSomethingElse {
    NSLog(@"doSomethingElse was called on %@", [self class]);
}


@end
