//
//  AppleScriptSafeExecutor.m
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/10/20.
//

#import "AppleScriptSafeExecutor.h"

@implementation AppleScriptSafeExecutor

+ (NSAppleEventDescriptor *)execute:(NSAppleScript *)script
                              error:(NSDictionary * __autoreleasing _Nullable * _Nullable)error {
    @try {
        return [script executeAndReturnError:error];
    }
    @catch (NSException *exception) {
        NSLog(@"⚠️ AppleScript Exception: %@", exception.reason);
        if (error) {
            *error = @{ @"NSExceptionReason": exception.reason ?: @"Unknown exception" };
        }
        return nil;
    }
}

@end
