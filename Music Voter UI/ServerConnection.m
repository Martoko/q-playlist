//
//  ServerConnection.m
//  Music Voter UI
//
//  Created by Martoko on 22/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "ServerConnection.h"

@interface ServerConnection ()

@property NSNetService* netService;
@property Connection* connectionToServer;

@end

@implementation ServerConnection

- (id)initWithNetService: (NSNetService*) netService
{
    self = [super init];
    if (self) {
        _voteTracks = [[NSMutableArray alloc] init];
        _netService = netService;
        _connectionToServer = nil;
    }
    return self;
}

- (void)dealloc
{
    self.connectionToServer.delegate = nil;
}

- (NSString*) getName {
    return self.netService.name;
}

- (void)connectIfNotConnected {
    if (self.connectionToServer == nil) {
        [self connect];
    }
}

- (void)connect {
    BOOL success = NO;
    
    NSInputStream* inputStream;
    NSOutputStream* outputStream;
    
    success = [self.netService getInputStream:&inputStream outputStream:&outputStream];
    
    if (success) {
        self.connectionToServer = [[Connection alloc] initWithInputStream:inputStream AndOutputStream:outputStream];
        self.connectionToServer.delegate = self;
    }
}

- (void)addTrack: (NSString*)trackURI {
    [self.connectionToServer sendAddTrack:trackURI];
}

- (void)addVoteForTrack: (VoteTrack*)voteTrack {
    NSString* userID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    [self.connectionToServer sendUser:userID addedVoteForTrack:voteTrack.track.uri.absoluteString];
}

- (void)removeVoteForTrack: (VoteTrack*)voteTrack {
    NSString* userID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    [self.connectionToServer sendUser:userID removedVoteForTrack:voteTrack.track.uri.absoluteString];
}

-(void)sortArrayAndSendTrackListChanged {
    [self sortArray];
    [self.delegate trackListChanged];
}

-(void)sortArray {
    [self.voteTracks sortUsingComparator:^NSComparisonResult(VoteTrack*  _Nonnull voteTrack1, VoteTrack*  _Nonnull voteTrack2) {
        return voteTrack1.remoteVotes.count < voteTrack2.remoteVotes.count;
    }];
}

#pragma mark - Connection delegate

- (void)connection:(Connection *)connection receivedAddTrack: (NSString*) trackURI {
    //check if track is already in list
    for (VoteTrack* voteTrack in self.voteTracks) {
        if ([voteTrack.track.uri.absoluteString isEqualToString:trackURI]) {
            return;
        }
    }
    
    NSURL* realTrackURI = [NSURL URLWithString:trackURI];
    [SPTTrack trackWithURI:realTrackURI session:nil callback:^(NSError *error, id track) {
        if (error == nil) {
            //check again if track is already in list
            for (VoteTrack* voteTrack in self.voteTracks) {
                if ([voteTrack.track.uri.absoluteString isEqualToString:trackURI]) {
                    return;
                }
            }
            
            VoteTrack* voteTrack = [[VoteTrack alloc] initWithTrack:track];
            [self.voteTracks addObject:voteTrack];
            [self sortArrayAndSendTrackListChanged];
        } else {
            NSLog(@"Error getting track %@ ", error.localizedDescription);
        }
    }];
}

- (void)connection:(Connection *)connection receivedRemoveTrack: (NSString*) trackURI {
    [self removeTrack:trackURI];
}

- (void)removeTrack: (NSString*) trackURI {
    VoteTrack* trackToRemove = nil;
    for (VoteTrack* voteTrack in self.voteTracks) {
        if ([voteTrack.track.uri.absoluteString isEqualToString: trackURI]) {
            trackToRemove = voteTrack;
        }
    }
    [self.voteTracks removeObject:trackToRemove];
    [self sortArrayAndSendTrackListChanged];
}

- (void)connection:(Connection *)connection user: (NSString*) userID addedVoteForTrack: (NSString*) trackURI {
    for (VoteTrack* voteTrack in self.voteTracks) {
        if ([voteTrack.track.uri.absoluteString isEqualToString: trackURI]) {
            // Makes sure there is no doubles votes
            [voteTrack.remoteVotes removeObject:userID];
            [voteTrack.remoteVotes addObject:userID];
        }
    }
    [self sortArrayAndSendTrackListChanged];
}

- (void)connection:(Connection *)connection user: (NSString*) userID removedVoteForTrack: (NSString*) trackURI {
    for (VoteTrack* voteTrack in self.voteTracks) {
        if ([voteTrack.track.uri.absoluteString isEqualToString: trackURI]) {
            // Makes sure there is no doubles votes
            [voteTrack.remoteVotes removeObject:userID];
        }
    }
    [self sortArrayAndSendTrackListChanged];
}

- (void)connection:(Connection *)connection receivedNowPlayingChangedTo: (NSString*) trackURI {
    NSURL* realTrackURI = [NSURL URLWithString:trackURI];
    
    [SPTTrack trackWithURI:realTrackURI session:nil callback:^(NSError *error, id track) {
        if (error == nil) {
            [self.delegate nowPlayingChangedTo:track];
        } else {
            NSLog(@"Error getting track %@ ", error.localizedDescription);
        }
    }];
    [self removeTrack:trackURI];
}

- (void)connectionTerminated:(Connection *)connection {
    [self.delegate connectionTerminated];
}

- (void)connectionEstablished:(Connection *)connection {
    [self.delegate connectionEstablished];
}

@end
