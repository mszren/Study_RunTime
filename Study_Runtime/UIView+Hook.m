//
//  UIView+Hook.m
//  Study_Runtime
//
//  Created by rytong on 2017/6/9.
//  Copyright © 2017年 rytong. All rights reserved.
//

#import "UIView+Hook.h"
#import <objc/runtime.h>

static NSHashTable *hashTable;

@implementation UIView (Hook)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        SEL originalSelector = @selector(init);
        SEL swizzledSelector = @selector(customInit);
        
        Method originalMethod = class_getInstanceMethod([self class], originalSelector);
        Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);
        
        BOOL didAddMethod = class_addMethod([self class], originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            class_replaceMethod([self class], swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        }else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
    });
}

- (instancetype)customInit {
    if (!hashTable) {
        hashTable = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    [hashTable addObject:self];
    return [self customInit];
}

- (NSArray *)showRecords {
    NSLog(@"records==>%@",hashTable.allObjects);
    return hashTable.allObjects;
}

@end
