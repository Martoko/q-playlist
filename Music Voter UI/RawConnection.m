//
//  Connection.m
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "RawConnection.h"

@interface RawConnection ()

@property NSInputStream* inputStream;
@property NSOutputStream* outputStream;

@property char separator;
@property NSMutableString* lastReadMessage;
@property int openStreams;

@property NSMutableArray<NSNumber *>* outputBuffer;
@property dispatch_queue_t bufferQueue;

- (BOOL) sendByteAndSucceded: (uint8_t)byte;
- (void) startStreams;
- (void) stopStreams;

- (void)tryToSendFromBuffer;

@end

@implementation RawConnection

-(id) init {
    return [self initWithInputStream:nil AndOutputStream:nil];
}

- (id) initWithInputStream: (NSInputStream*) inputStream AndOutputStream: (NSOutputStream*) outputStream {
    self = [super init];
    
    if (self) {
        _separator = ';';
        _inputStream = inputStream;
        _outputStream = outputStream;
        _openStreams = 0;
        _outputBuffer = [[NSMutableArray alloc] init];
        _bufferQueue = dispatch_queue_create("bufferQueue", DISPATCH_QUEUE_SERIAL);
        _lastReadMessage = [[NSMutableString alloc] init];
        [self startStreams];
    }
    
    return self;
}

- (void) startStreams {
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    
    [self.inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.inputStream  open];
    [self.outputStream open];
}

- (void) dealloc {
    [self stopStreams];
}

- (void) stopStreams {    
    [self.inputStream setDelegate:nil];
    [self.outputStream setDelegate:nil];
    
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.inputStream close];
    [self.outputStream close];
    
    [self.delegate connectionTerminated:self];
}

- (void) sendMessage:(NSString *)string {
    dispatch_async(self.bufferQueue, ^{
        const char* cString = [string UTF8String];
        for (size_t i = 0; i < strlen(cString); i++) {
            NSNumber* byteNumber = [[NSNumber alloc] initWithUnsignedInt:(uint8_t)cString[i]];
            [self.outputBuffer addObject:byteNumber];
        }
        NSNumber* byteNumber = [[NSNumber alloc] initWithUnsignedInt:(uint8_t)self.separator];
        [self.outputBuffer addObject:byteNumber];
        
        [self tryToSendFromBuffer];
    });
}

- (BOOL)sendByteAndSucceded:(uint8_t)byte
{
    // Only write to the stream if it has space available, otherwise we might block.
    
    if ( [self.outputStream hasSpaceAvailable] ) {
        NSInteger   bytesWritten;
        
        bytesWritten = [self.outputStream write:&byte maxLength:sizeof(byte)];
        
        if (bytesWritten != sizeof(byte)) {
            [self stopStreams];
        }
        
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)sendBytesAndSucceded:(uint8_t*)bytes WithLength: (NSInteger) length {
    if( [self.outputStream hasSpaceAvailable] ) {
        NSInteger bytesWritten = [self.outputStream write:bytes maxLength:sizeof(bytes)];
        
        if (bytesWritten != length) {
            [self stopStreams];
        }
        
        return YES;
        
    } else {
        return NO;
    }
    
}

- (void)tryToSendFromBuffer {
    while ([self.outputStream hasSpaceAvailable] && self.outputBuffer.count > 0) {
    
    //Only send if buffer has space and there is something in our manual buffer
    while ([self.outputStream hasSpaceAvailable] && self.outputBuffer.count > 0) {
        NSNumber* latestByte = self.outputBuffer.firstObject;
        
        uint8_t byte = [latestByte unsignedIntValue];
        BOOL didSendByte = [self sendByteAndSucceded:byte];
        if (didSendByte) {
            [self.outputBuffer removeObjectAtIndex:0];
        }
//        while (didSendByte == NO) {
//            didSendByte = [self sendByteAndSucceded:byte];
//        }
    }
    }
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    switch(eventCode) {
            
        case NSStreamEventOpenCompleted: {
            self.openStreams++;
            if (self.openStreams == 2) {
                [self.delegate connectionEstablished:self];
            }
        } break;
            
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[1024];
            unsigned long bytesRead;
        
            bytesRead = [self.inputStream read:buffer maxLength:1024];
            if (bytesRead <= 0) {
                // Do nothing; we'll handle EOF and error in the
                // NSStreamEventEndEncountered and NSStreamEventErrorOccurred case,
                // respectively.
            } else {
                NSMutableString* readString = [[NSMutableString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding];
                
                // UTF decode can leave an empty string, typically if it is garbage
                if (readString) {
                    NSRange foundSeparator = [readString rangeOfString:[NSString stringWithFormat:@"%c", self.separator]];
                    
                    while (foundSeparator.location != NSNotFound) {
                        [self.lastReadMessage appendString: [readString substringToIndex:foundSeparator.location]];
                        [readString deleteCharactersInRange:NSMakeRange(0, foundSeparator.location+1)];
                        [self.delegate connection:self receivedMessage:self.lastReadMessage];
                        [self.lastReadMessage setString:@""];
                        
                        foundSeparator = [readString rangeOfString:[NSString stringWithFormat:@"%c", self.separator]];
                    }
                    
                    [self.lastReadMessage appendString:readString];
                }
            }
        } break;
            
        case NSStreamEventErrorOccurred:break;
        case NSStreamEventEndEncountered: {
            [self stopStreams];
        } break;
        
        case NSStreamEventHasSpaceAvailable: {
            dispatch_async(self.bufferQueue, ^{
                [self tryToSendFromBuffer];
                
            });
        } break;
        case NSStreamEventNone: break;
    }
}

@end
