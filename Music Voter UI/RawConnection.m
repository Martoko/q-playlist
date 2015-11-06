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

@property NSMutableArray* outputBuffer;

- (void) sendCharacter: (char) character;
- (void) sendByte: (uint8_t)byte;
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
    const char* cString = [string UTF8String];
    for (size_t i = 0; i < strlen(cString); i++) {
        [self sendCharacter: cString[i]];
    }
    [self sendCharacter: self.separator];
}

- (void) sendCharacter:(char)character {
    NSNumber* byteNumber = [[NSNumber alloc] initWithUnsignedInt:(uint8_t)character];
    [self.outputBuffer addObject:byteNumber];
    [self tryToSendFromBuffer];
}

- (void)sendByte:(uint8_t)byte
{
    // Only write to the stream if it has space available, otherwise we might block.
    // In a real app you have to handle this case properly
    
    if ( [self.outputStream hasSpaceAvailable]) {
        NSInteger   bytesWritten;
        
        bytesWritten = [self.outputStream write:&byte maxLength:sizeof(byte)];
        
        if (bytesWritten != sizeof(byte)) {
            [self stopStreams];
        }
    } else {
        //Should never happen
        assert(NO);
    }
}

- (void)tryToSendFromBuffer {
    //Only send if buffer has space and there is something in our manual buffer
    while ([self.outputStream hasSpaceAvailable] && self.outputBuffer.count > 0) {
        NSNumber* latestByte = self.outputBuffer.firstObject;
        [self.outputBuffer removeObjectAtIndex:0];
        
        uint8_t byte = [latestByte unsignedIntValue];
        [self sendByte:byte];
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
            uint8_t     b;
            NSInteger   bytesRead;
            
            bytesRead = [self.inputStream read:&b maxLength:sizeof(uint8_t)];
            if (bytesRead <= 0) {
                // Do nothing; we'll handle EOF and error in the
                // NSStreamEventEndEncountered and NSStreamEventErrorOccurred case,
                // respectively.
            } else {
                char character = (char)b;
                if(character == self.separator) {
                    [self.delegate connection:self receivedMessage:self.lastReadMessage];
                    [self.lastReadMessage setString:@""];
                    
                } else if (character == '\r' || character == '\n') {
                    // Newlines are ignored so we can telnet into it
                    
                } else {
                    [self.lastReadMessage appendFormat:@"%c", character];
                }
            }
        } break;
            
        case NSStreamEventErrorOccurred:break;
        case NSStreamEventEndEncountered: {
            [self stopStreams];
        } break;
        
        case NSStreamEventHasSpaceAvailable: {
            [self tryToSendFromBuffer];
        } break;
        case NSStreamEventNone: break;
    }
}

@end
