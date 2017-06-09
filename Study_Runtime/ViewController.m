//
//  ViewController.m
//  Study_Runtime
//
//  Created by rytong on 2017/6/8.
//  Copyright © 2017年 rytong. All rights reserved.
//

#import "ViewController.h"
#import "SomeClass.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self study_Runtime];
}


- (void)study_Runtime{
    

//    [self getIMPAdress];
    
    [self resolveBindMethod];
    
//    [self forwardMethod];
}

/**
 获取函数地址
 */
- (void)getIMPAdress{
    

    
    void (*setter)(id, SEL, BOOL);//设置对应的函数指针类型
    
    /*
     使用methodForSelector:绕开动态绑定节约了消息传递时时间
     */
    setter = (void (*)(id, SEL, BOOL))[self methodForSelector:@selector(setFilled:)];
    for (int i = 0; i < 2; i++) {
        setter(self, @selector(setFilled:), YES);//通过函数指针调用对应实现
    }
    
//        SEL aselector = @selector(setFilled:);
//        IMP aimp = [self methodForSelector:aselector];
//        void (*setter2)(id, SEL, BOOL) = (void(*)(id, SEL, BOOL))aimp;
//        setter2(self, aselector, YES);

}


/**
 消息动态解析
 */
- (void)resolveBindMethod {
    
    SomeClass *objec = [[SomeClass alloc]init];
    objec.objectTag = 10.0f;
    float tag = objec.objectTag;
    
//    SEL aselector = @selector(MissMethod);
//    IMP aimp = [objec methodForSelector:aselector];
//    void (*setter)(id, SEL) = (void (*)(id, SEL))aimp;
//    setter(objec, aselector);
    
}

/**
 消息转发
 */
- (void)forwardMethod {
    SomeClass *objec = [SomeClass new];

    SEL aselector = @selector(doSomethingElse);
    IMP aimp = [objec methodForSelector:aselector];
    void (*setter)(id, SEL) = (void (*)(id, SEL))aimp;
    setter(objec, aselector);
}

- (void)setFilled:(BOOL)boolValue {
    NSLog(@"%d",boolValue);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end















