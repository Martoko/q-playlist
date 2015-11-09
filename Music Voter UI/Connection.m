//
//  Connection.m
//  Music Voter UI
//
//  Created by Martoko on 29/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "Connection.h"

@interface Connection ()

@property RawConnection* rawConnection;
@property NSString* separator;

@end

@implementation Connection

- (id) initWithInputStream: (NSInputStream*) inputStream AndOutputStream: (NSOutputStream*) outputStream {
    self = [super init];
    if (self) {
        _rawConnection = [[RawConnection alloc] initWithInputStream:inputStream AndOutputStream:outputStream];
        _rawConnection.delegate = self;
        _separator = @"^";
    }
    return self;
}

#pragma mark - Send Commands

- (void)sendAddTrack: (NSString*) trackURI {
    [self sendCommandAndArgs:@"addTrack", trackURI, nil];
}

- (void)sendRemoveTrack: (NSString*) trackURI {
    [self sendCommandAndArgs:@"removeTrack", trackURI, nil];
}

- (void)sendUser: (NSString*) userID addedVoteForTrack: (NSString*) trackURI {
    [self sendCommandAndArgs:@"userAddedVoteToTrack", userID, trackURI, nil];
}

- (void)sendUser: (NSString*) userID removedVoteForTrack: (NSString*) trackURI {
    [self sendCommandAndArgs:@"userRemovedVoteFromTrack", userID, trackURI, nil];
}

- (void)sendNowPlayingChangedTo: (NSString*) trackURI {
    [self sendCommandAndArgs:@"nowPlayingChangedToTrack", trackURI, nil];
}

#pragma mark - Constructing and Parsing of messages

- (void) parseMessage: (NSString*) message {
    NSArray* commandAndArgs = [message componentsSeparatedByString:self.separator];
    
    
    if ([commandAndArgs[0] isEqualToString:@"addTrack"]) {
        [self.delegate receivedAddTrack:commandAndArgs[1]];
        
    } else if ([commandAndArgs[0] isEqualToString:@"removeTrack"]) {
        [self.delegate receivedRemoveTrack:commandAndArgs[1]];
        
    } else if ([commandAndArgs[0] isEqualToString:@"userAddedVoteToTrack"]) {
        [self.delegate user:commandAndArgs[1] addedVoteForTrack:commandAndArgs[2]];
        
    } else if ([commandAndArgs[0] isEqualToString:@"userRemovedVoteFromTrack"]) {
        [self.delegate user:commandAndArgs[1] removedVoteForTrack:commandAndArgs[2]];
        
    } else if ([commandAndArgs[0] isEqualToString:@"nowPlayingChangedToTrack"]) {
        [self.delegate receivedNowPlayingChangedTo:commandAndArgs[1]];
        
    } else {
        NSLog(@"Received unknown command: %@", commandAndArgs[0]);
    }
}


- (void) sendCommandAndArgs: (NSString*)argString, ... NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray* commandAndArgs = [[NSMutableArray alloc] init];
    
    // Voodo magic, lookup "va_list obj-c" on google
    va_list va_strings;
    va_start(va_strings, argString);
    
    [commandAndArgs addObject:argString];
    
    id arg = nil;
    while((arg = va_arg(va_strings, id))) {
        [commandAndArgs addObject:arg];
    }
    
    va_end(va_strings);
    //end of voodo magic
    
    NSString* message = [commandAndArgs componentsJoinedByString:self.separator];
    [self.rawConnection sendMessage:message];
}

#pragma mark - RawConnectionDelegate

-(void)connection:(RawConnection *)connection receivedMessage:(NSString *)message {
    [self parseMessage:message];
}

-(void)connectionTerminated:(RawConnection *)connection {
    [self.delegate connectionTerminated:self];
}

-(void)connectionEstablished:(RawConnection *)connection {
    [self.delegate connectionEstablished:self];
}

@end
