//
//  AppleScriptSafeExecutor.h
//  DynamicHelper
//
//  Created by 吳佳昇 on 2025/10/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppleScriptSafeExecutor : NSObject

+ (NSAppleEventDescriptor * _Nullable)execute:(NSAppleScript *)script
                                        error:(NSDictionary * __autoreleasing _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
