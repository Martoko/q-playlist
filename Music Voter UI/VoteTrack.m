//
//  VoteTrack.m
//  Music Voter UI
//
//  Created by Martoko on 23/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "VoteTrack.h"

@implementation VoteTrack

- (id)init
{
    return [self initWithTrack:nil];;
}

- (id)initWithTrack: (SPTPartialTrack*) track
{
    self = [super init];
    if (self) {
        _track = track;
        _remoteVotes = [[NSMutableArray alloc] init];
    }
    return self;
}

-(BOOL) userHasVoted: (NSString*) userID {
    return [self.remoteVotes containsObject:userID];
}

@end
