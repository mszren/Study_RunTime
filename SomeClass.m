//
//  SomeClass.m
//  Study_Runtime
//
//  Created by rytong on 2017/6/8.
//  Copyright © 2017年 rytong. All rights reserved.
//

/************************************************************
*OC的消息只有在执行时才会去寻找方法的实现，通过类的dispatch_table表来查找selector和方法的实现，如果在类和其父类中都找不到就会进入到动态方法决议，决议不通过则进入方法转发
 
 创建一个对象负责把消息转发给一个由其它对象组成的响应链，代理对象会在这个有其它对象组成的集合里寻找能够处理该消息的对象；
 把一个对象包在一个logger对象里，用来拦截或者纪录一些有趣的消息调用；
 比如声明类的属性为dynamic，使用自定义的方法来截取和取代由系统自动生成的getter和setter方法。
 */
 
#import "SomeClass.h"
#import <objc/runtime.h>
#import "ForwardClass.h"

static char * ObjectTagKey = "";
@interface SomeClass ()


@end

@implementation SomeClass{
    id forwardClass;
}
//@dynamic objectTag;


- (id)init {
    if (self = [super init]) {
        forwardClass = [ForwardClass new];
    }
    return self;
}

- (void)doSomething {
    
    NSLog(@"doSomething was called on %@", [self class]);
}

#pragma mark - 动态决议

/**
 添加setter实现
 */
void dynamicSetMethod(id self, SEL _cmd, float w) {
    
    printf("dynamicSetMeghod-%s\n",[NSStringFromSelector(_cmd) cStringUsingEncoding:NSUTF8StringEncoding]);
    
    printf("%f\n",w);
    objc_setAssociatedObject(self, ObjectTagKey, [NSNumber numberWithFloat:w], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void dynamicMethodIMP(id self, SEL _cmd) {
    NSLog(@" >> dynamicMethodIMP");
}

/**
 添加getter实现
 */
void dynamicGetMethod(id self, SEL _cmd) {
    printf("dynamicMethod-%s\n",[NSStringFromSelector(_cmd)
                                 cStringUsingEncoding:NSUTF8StringEncoding]);
    objc_getAssociatedObject(self, ObjectTagKey);
}

/**
 解析selector方法(动态方法决议,对象方法)
 */
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    
    NSString *methodName = NSStringFromSelector(sel);
    BOOL result = NO;
    /*
     动态的添加setter和getter方法
     */
    if ([methodName isEqualToString:@"setObjectTag:"]) {
        class_addMethod([self class], sel, (IMP)dynamicSetMethod, "v@:f");
        result = YES;
    }else if ([methodName isEqualToString:@"objectTag"]){
        class_addMethod([self class], sel, (IMP)dynamicGetMethod, "v@:f");
        result = YES;
    }else if ([methodName isEqualToString:@"MissMethod"]){
        class_addMethod([self class], sel, (IMP)dynamicMethodIMP, "v@:");
        result = YES;
    }
    return result;
}

/**
 解析selector方法(动态方法决议,类方法)
 */
+ (BOOL)resolveClassMethod:(SEL)sel {
    return [super resolveClassMethod:sel];
}

#pragma mark - 消息转发

/**
 消息转发
 */
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    
    if (!forwardClass) {
        [self doesNotRecognizeSelector:[anInvocation selector]];
    }
    [anInvocation invokeWithTarget:forwardClass];
}

/**
 消息转发前先执行此方法
 */
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        //生成方法签名
        signature = [forwardClass methodSignatureForSelector:aSelector];
    }
    return signature;
}

@end














