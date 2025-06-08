//
//  bridge.h
//  Stats
//
//  Created by Serhiy Mytrovtsiy on 17/12/2024
//  Using Swift 6.0
//  Running on macOS 15.1
//
//  Copyright © 2024 Serhiy Mytrovtsiy. All rights reserved.
//  

#ifndef bridge_h
#define bridge_h

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hidsystem/IOHIDEventSystemClient.h>

#ifdef __LP64__
typedef double IOHIDFloat;
#else
typedef float IOHIDFloat;
#endif

#define IOHIDEventFieldBase(type)   (type << 16)
#define kIOHIDEventTypeTemperature  15
#define kIOHIDEventTypePower        25

typedef struct IOReportSubscriptionRef* IOReportSubscriptionRef;
typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;

void IOReportMergeChannels(CFDictionaryRef a, CFDictionaryRef b, CFTypeRef null);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
IOReportSubscriptionRef IOReportCreateSubscription(void* a, CFMutableDictionaryRef b, CFMutableDictionaryRef* c, uint64_t d, CFTypeRef e);
IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
IOHIDFloat IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);
IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef, int64_t , int32_t, int64_t);

CFDictionaryRef IOReportCreateSamples(IOReportSubscriptionRef a, CFMutableDictionaryRef b, CFTypeRef c);
CFDictionaryRef IOReportCreateSamplesDelta(CFDictionaryRef a, CFDictionaryRef b, CFTypeRef c);
CFDictionaryRef IOReportCopyChannelsInGroup(CFStringRef a, CFStringRef b, uint64_t c, uint64_t d, uint64_t e);

CFStringRef IOReportChannelGetGroup(CFDictionaryRef a);
CFStringRef IOReportChannelGetSubGroup(CFDictionaryRef a);
CFStringRef IOReportChannelGetChannelName(CFDictionaryRef a);
CFStringRef IOReportChannelGetUnitLabel(CFDictionaryRef a);
CFStringRef IOReportStateGetNameForIndex(CFDictionaryRef a, int32_t b);

CFTypeRef IOHIDServiceClientCopyProperty(IOHIDServiceClientRef service, CFStringRef property);

int32_t IOReportStateGetCount(CFDictionaryRef a);
int64_t IOReportStateGetResidency(CFDictionaryRef a, int32_t b);
int64_t IOReportSimpleGetIntegerValue(CFDictionaryRef a, int32_t b);

NSDictionary*AppleSiliconSensors(int page, int usage, int32_t type);





#endif /* bridge_h */
