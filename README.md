# Study_RunTime
一、消息传递的过程

在object-c中,消息直到运行的时候才会绑定对应的实现，也就是说一开始方法和方法的实现是互相拆分开来的，并且object-c中也是允许我们来对其进行自由组合。

objc_msgSend(class, selector）//or objc_msgSend(class, selector, arg1, arg2, ...)
这里有必要再提一下，要实现消息的传递关键在于每个继承于NSObject的类都能自动获得runtime的支持。每个类中都存在两个重要的元素：

isa指针，指向该类定义的数据结构体,这个结构体是由编译器编译时为类（需继承于NSObject）创建的.在这个结构体中有包括了指向其父类类定义的指针
类的分发表( dispatch table)，该表包含selector的名称及对应实现函数的地址
消息执行的时候，首先根据传递对象的isa指针找到类的结构，每个类中都存在一个单独的擦车或methodlist，它可以缓存继承或自定义的方法。根据selector名字会首先检查class类的cache是否已经缓存对应的selector，如果有就直接调用对应的实现IMP

如果在cache中找不到就会在其分发表中寻找对应的selector，找到的话就调用对应的实现；找不到则会根据super class指针去其父类寻找，如果父类还找不到，会接着去父类的父类中寻找，直到NSObject类为止

如果没有找到，并且实现了动态方法决议机制就会决议：resolveInstanceMethod和resolveClassMethod

如果没有实现动态决议机制或者决议失败且实现了消息转发机制。就会进入消息转发流程。否则程序Crash（如果同时实现了动态决议和消息转发。那么动态决议先于消息转发。只有当动态决议无法决议selector的实现，才会尝试进行消息转发。）

二、 获取函数地址

通过直接获取函数指针来绕过消息的绑定实现对函数的直接调用，可以节约消息传递的时间。
methodForSelector:方法你可以获取selector对应实现的指针，该指针必须转换成合适的函数类型：

SEL aSelector = @selector(setFilled:);//设置对应的函数指针类型
/*
使用methodForSelector:绕开动态绑定节约了消息传递时时间
*/
IMP aIMP = [self methodForSelector:aSelector];
void (*setter)(id, SEL, NSString *) = (void(*)(id, SEL, NSString *))aIMP;
setter(self, aSelector, @"哈哈");//通过函数指针调用对应实现
三、 消息的动态决议

通过resolveInstanceMethod:和 resolveClassMethod:动态的为selector提供实现方法，在这里你可以通过方法名来对消息的传递进行拦截来实现你的一些特殊需求：比如对无法处理消息的crash拦截处理或者替换系统API。
objective-c方法本质上就是一个带有至少两个参数（_self和_cmd）的c函数，你可以通过 class_addMethod为类添加一个函数

#import "SomeClass.h"
#import <objc/runtime.h>

static char * ObjectTagKey = "";
@interface SomeClass ()

@end

@implementation SomeClass{
}
//@dynamic objectTag;

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
    }
    return result;
}

/**
 解析selector方法(动态方法决议,类方法)
 */
+ (BOOL)resolveClassMethod:(SEL)sel {
    return [super resolveClassMethod:sel];
}
/**
 动态决议调用
 */
- (void)resolveBindMethod {

    SomeClass *objec = [[SomeClass alloc]init];
    objec.objectTag = 10.0f;
    float tag = objec.objectTag;
}
四、 消息的转发

每一个对象都从NSObject类继承了forwardInvocation:方法，但在NSObject中，该方法只是简单的调用doesNotRecognizeSelector:，通过重写该方法你就可以利用forwardInvocation:将消息转发给其它对象。

先调用methodSignatureForSelector:获取指定selector的方法签名
重写forwardInvocation方法，调用invokeWithTarget来确定消息转发的对象和对应的原始参数
#import "SomeClass.h"
#import <objc/runtime.h>
#import "ForwardClass.h"

@implementation SomeClass{
    id forwardClass;
}

- (id)init {
    if (self = [super init]) {
        forwardClass = [ForwardClass new];
    }
    return self;
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
/**
 消息转发调用
 */
- (void)forwardMethod {
    SomeClass *objec = [SomeClass new];

    SEL aselector = @selector(doSomethingElse);
    IMP aimp = [objec methodForSelector:aselector];
    void (*setter)(id, SEL) = (void (*)(id, SEL))aimp;
    setter(objec, aselector);
}
消息转发有很多的用途，比如：

创建一个对象负责把消息转发给一个由其它对象组成的响应链，代理对象会在这个有其它对象组成的集合里寻找能够处理该消息的对象；
把一个对象包在一个logger对象里，用来拦截或者纪录一些有趣的消息调用；
比如声明类的属性为dynamic，使用自定义的方法来截取和取代由系统自动生成的getter和setter方法。
五、 Method Swizzling

Method Swizzling:被灌醉的方法
前面也曾提到过，object-c中也是允许我们来对方法和方法的实现进行自由组合的，原理也就是替换掉对应方法的函数指针IMP，达到另类的方法实现
通过RunTime的Swizzling我们可以做很多事情：比如目前流行的无埋点统计中的事件圈选以及APM的页面慢交互分析，底层都是通过改变类的分发表里selector和实现之间的对应关系，来进行信息捕获的

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
以上所说的主要还是针对RunTime的消息传递来说的，其实RunTime的用途还有很多，一些基础的class_copyIvarList、class_copyMethodList、class_copyProtocolList、class_copyPropertyList的使用在这里就不在多说了，有兴趣的同学可以自行在网上查找。
