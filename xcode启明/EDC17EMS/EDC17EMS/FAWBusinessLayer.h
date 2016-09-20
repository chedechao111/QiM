//
//  FAWBusinessLayer.h
//  EDC17EMS
//
//  Created by Zephyr on 2015-6-15.
//  Copyright (c) 2015年 China FAW R&D Center. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    Success,
    Timeout,
    Canceled,
    NoResponse,
    InnerError,
    AuthenticationFailure,
    NegativeResponse,
    InvalidProtocol,
    InvalidParameter,
    IoControlFailure,
    TransmissionFailure,
    RoutineControlFailure,
    RoutineControlPending,
    RoutineControlTimeout,
    RoutineControlException,
    RoutineControlUnknown
} Error;

@interface FAWBusinessLayer : NSObject
{
    int mySocket;
}

- (Error)prepareOperation;
- (Error)readData:(NSData **)data byIdentifier:(unsigned short)identifier;
- (Error)startIoControlWithData:(NSData *)data byIdentifier:(unsigned short)identifier;
- (Error)stopIoControlByIdentifier:(unsigned short)identifier;
- (Error)startRoutineControlByIdentifier:(unsigned short)identifier withData:(NSData *)data;
- (Error)getRoutineControlStatusByIdentifier:(unsigned short)identifier;
- (Error)stopRoutineControlByIdentifier:(unsigned short)identifier;
- (Error)readCurrentDTCToArray:(NSArray **)array;
- (Error)readConfirmedDTCToArray:(NSArray **)array;
- (Error)clearDTC;
- (Error)readFrozenFramesToData:(NSData **)framesData byDTCData:(NSData *)dtcData;
- (Error)changeSessionMode:(NSInteger)sessionId;
- (Error)passAccessLimit;
- (Error)readData:(NSData **)data byAddress:(NSData *)address andLength:(ushort)length;
- (NSString *)getErrorMessage:(Error)error;

@end
