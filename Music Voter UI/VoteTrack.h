//
//  VoteTrack.h
//  Music Voter UI
//
//  Created by Martoko on 23/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>

@interface VoteTrack : NSObject

@property SPTPartialTrack* track;
@property NSMutableArray* remoteVotes;
- (BOOL)userHasVoted: (NSString*) userID;

- (id)initWithTrack: (SPTPartialTrack*) track;

@end
