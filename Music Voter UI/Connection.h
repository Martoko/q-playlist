//
//  Connection.h
//  Music Voter UI
//
//  Created by Martoko on 29/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RawConnection.h"

@interface Connection : NSObject <RawConnectionDelegate>

@property (nonatomic, weak) id delegate;

- (id) initWithInputStream: (NSInputStream*) inputStream AndOutputStream: (NSOutputStream*) outputStream;

- (void)sendAddTrack: (NSString*) trackURI;
- (void)sendRemoveTrack: (NSString*) trackURI;
- (void)sendUser: (NSString*) userID addedVoteForTrack: (NSString*) trackURI;
- (void)sendUser: (NSString*) userID removedVoteForTrack: (NSString*) trackURI;
- (void)sendNowPlayingChangedTo: (NSString*) trackURI;

@end


@protocol ConnectionDelegate <NSObject>

@optional

- (void)connection:(Connection *)connection receivedAddTrack: (NSString*) trackURI;
- (void)connection:(Connection *)connection receivedRemoveTrack: (NSString*) trackURI;

- (void)connection:(Connection *)connection user: (NSString*) userID addedVoteForTrack: (NSString*) trackURI;
- (void)connection:(Connection *)connection user: (NSString*) userID removedVoteForTrack: (NSString*) trackURI;

- (void)connection:(Connection *)connection receivedNowPlayingChangedTo: (NSString*) trackURI;

- (void)connectionTerminated:(Connection *)connection;
- (void)connectionEstablished:(Connection *)connection;

@end