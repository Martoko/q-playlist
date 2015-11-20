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
#import "MusicVoterConnectionProtocol.h"

@interface ServerConnection : NSObject <ConnectionDelegate, MusicVoterConnection>

@property (nonatomic, weak) id<MusicVoterConnectionDelegate> delegate;
@property (readonly) NSMutableArray<VoteTrack*>* voteTracks;

// Hide parameterless init
-(id)init __attribute__((unavailable("init not available, use initWithNetService")));
+(id)new __attribute__((unavailable("new not available, use alloc and initWithNetService")));

- (id)initWithNetService: (NSNetService*) netService;

- (NSString*) getName;

- (void)sendAddTrack: (NSString*) trackURI;
- (void)sendAddedVoteForTrack: (NSString*) trackURI;
- (void)sendRemovedVoteForTrack: (NSString*) trackURI;

@end