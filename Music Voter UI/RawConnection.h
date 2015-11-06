//
//  Connection.h
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RawConnection : NSObject <NSStreamDelegate>

@property (nonatomic, weak) id delegate;

- (id) initWithInputStream: (NSInputStream*) inputStream AndOutputStream: (NSOutputStream*) outputStream;
- (void) sendMessage: (NSString*) string;

@end


@protocol RawConnectionDelegate <NSObject>

-(void)connection:(RawConnection *)connection receivedMessage:(NSString *)message;
-(void)connectionTerminated:(RawConnection *)connection;
-(void)connectionEstablished:(RawConnection *)connection;

@end