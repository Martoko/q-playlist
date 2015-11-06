//
//  ServerConnection.h
//  Music Voter UI
//
//  Created by Martoko on 22/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>
#import "Connection.h"
#import "VoteTrack.h"


@interface ServerConnection : NSObject <ConnectionDelegate>

@property (nonatomic, weak) id delegate;
@property NSMutableArray<VoteTrack*>* voteTracks;

// Hide parameterless init
-(id)init __attribute__((unavailable("init not available, use initWithNetService")));
+(id)new __attribute__((unavailable("new not available, use alloc and initWithNetService")));

- (id)initWithNetService: (NSNetService*) netService;

- (NSString*) getName;

- (void)connectIfNotConnected;
- (void)connect;

- (void)addTrack: (NSString*)trackURI;
- (void)addVoteForTrack: (VoteTrack*)voteTrack;
- (void)removeVoteForTrack: (VoteTrack*)voteTrack;

@end

@protocol ServerConnectionDelegate <NSObject>

- (void)connectionEstablished;
- (void)connectionTerminated;
- (void)trackListChanged;
- (void)nowPlayingChangedTo: (SPTPartialTrack*)track;

@end