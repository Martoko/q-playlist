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
@property NSMutableArray* voteTracks;
@property dispatch_queue_t voteTracksQueue;

@end

@implementation ServerConnection

- (id)initWithNetService: (NSNetService*) netService
{
    self = [super init];
    if (self) {
        _voteTracks = [[NSMutableArray alloc] init];
        _netService = netService;
        _connectionToServer = nil;
        _voteTracksQueue = dispatch_queue_create("joinVoteTracksQueue", DISPATCH_QUEUE_SERIAL);
    } else {
        NSLog(@"Error initializing server connection's parent");
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

- (NSArray<VoteTrack*>*) getVoteTracks {
    return [[NSArray alloc] initWithArray:self.voteTracks];
}

- (void)connectIfNot {
    if (self.connectionToServer == nil) {
        BOOL success = NO;
    
        NSInputStream* inputStream;
        NSOutputStream* outputStream;
    
        success = [self.netService getInputStream:&inputStream outputStream:&outputStream];
    
        if (success) {
            self.connectionToServer = [[Connection alloc] initWithInputStream:inputStream AndOutputStream:outputStream];
            self.connectionToServer.delegate = self;
        }
    }
}

- (void)sendAddTrack: (NSString*)trackURI {
    [self.connectionToServer sendAddTrack:trackURI];
}

- (void)sendAddedVoteForTrack: (NSString*)trackURI {
    NSString* userID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    [self.connectionToServer sendUser:userID addedVoteForTrack:trackURI];
}

- (void)sendRemovedVoteForTrack: (NSString*)trackURI {
    NSString* userID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    [self.connectionToServer sendUser:userID removedVoteForTrack:trackURI];
}

-(void)sortArrayAndSendTrackListChanged {
    [self sortArray];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate trackListChanged:[self getVoteTracks]];
    });
}

-(void)sortArray {
    NSSortDescriptor *remoteVotesSorter = [[NSSortDescriptor alloc] initWithKey:@"remoteVotes.@count" ascending:NO];
    NSSortDescriptor *playableUriSorter = [[NSSortDescriptor alloc] initWithKey:@"track.uri.absoluteString" ascending:NO];
    
    [self.voteTracks sortUsingDescriptors:[NSArray arrayWithObjects:remoteVotesSorter, playableUriSorter, nil]];
}

#pragma mark - Connection delegate

- (void)receivedAddTrack: (NSString*) trackURI {
    __weak ServerConnection* weakSelf = self;
    dispatch_async(self.voteTracksQueue, ^{
        //check if track is already in list
        for (VoteTrack* voteTrack in weakSelf.voteTracks) {
            if ([voteTrack.track.uri.absoluteString isEqualToString:trackURI]) {
                return;
            }
        }
    
        NSURL* realTrackURI = [NSURL URLWithString:trackURI];
        [SPTTrack trackWithURI:realTrackURI session:nil callback:^(NSError *error, id track) {
            if (error == nil) {
                [weakSelf addTrack: track];
                
            } else {
                NSLog(@"Error getting track %@ ", error.localizedDescription);
            }
        }];
    });
    
}

- (void)addTrack: (SPTTrack*) track {
    __weak ServerConnection* weakSelf = self;
    dispatch_async(weakSelf.voteTracksQueue, ^{
        //check again if track is already in list
        for (VoteTrack* voteTrack in weakSelf.voteTracks) {
            if ([voteTrack.track.uri.absoluteString isEqualToString:track.uri.absoluteString]) {
                return;
            }
        }
        
        VoteTrack* voteTrack = [[VoteTrack alloc] initWithTrack:track];
        [weakSelf.voteTracks addObject:voteTrack];
        [weakSelf sortArrayAndSendTrackListChanged];
    });
}

- (void)receivedRemoveTrack: (NSString*) trackURI {
    __weak ServerConnection* weakSelf = self;
    dispatch_async(self.voteTracksQueue, ^{
        VoteTrack* trackToRemove = nil;
        for (VoteTrack* voteTrack in weakSelf.voteTracks) {
            if ([voteTrack.track.uri.absoluteString isEqualToString: trackURI]) {
                trackToRemove = voteTrack;
            }
        }
        [weakSelf.voteTracks removeObject:trackToRemove];
        [weakSelf sortArrayAndSendTrackListChanged];
    });
    
}

- (void)user: (NSString*) userID addedVoteForTrack: (NSString*) trackURI {
    __weak ServerConnection* weakSelf = self;
    dispatch_async(self.voteTracksQueue, ^{
        BOOL alreadyInList = NO;
        VoteTrack* chosenVoteTrack;
        for (VoteTrack* voteTrack in weakSelf.voteTracks) {
            if ([voteTrack.track.uri.absoluteString isEqualToString: trackURI]) {
                chosenVoteTrack = voteTrack;
                alreadyInList = YES;
            }
        }
        
        if (alreadyInList) {
            // Makes sure there is no doubles votes
            [chosenVoteTrack.remoteVotes removeObject:userID];
            [chosenVoteTrack.remoteVotes addObject:userID];
            [weakSelf sortArrayAndSendTrackListChanged];
            
        } else if (alreadyInList == NO) {
            NSURL* realTrackURI = [NSURL URLWithString:trackURI];
            [SPTTrack trackWithURI:realTrackURI session:nil callback:^(NSError *error, id track) {
                if (error == nil) {
                    [weakSelf addTrack:track];
                    [weakSelf user:userID addedVoteForTrack:trackURI];
                } else {
                    NSLog(@"Error getting track %@ ", error.localizedDescription);
                }
            }];
        }
    });
}

- (void)user: (NSString*) userID removedVoteForTrack: (NSString*) trackURI {
    __weak ServerConnection* weakSelf = self;
    dispatch_async(self.voteTracksQueue, ^{
        for (VoteTrack* voteTrack in weakSelf.voteTracks) {
            if ([voteTrack.track.uri.absoluteString isEqualToString: trackURI]) {
                [voteTrack.remoteVotes removeObject:userID];
            }
        }
        [weakSelf sortArrayAndSendTrackListChanged];
    });
    
}

- (void)receivedNowPlayingChangedTo: (NSString*) trackURI {
    NSURL* realTrackURI = [NSURL URLWithString:trackURI];
    
    if ([trackURI  isEqualToString: @"none"]) {
        [self.delegate nowPlayingChangedTo:[[SPTTrack alloc] init]];
    } else {
        __weak ServerConnection * weakSelf = self;
        [SPTTrack trackWithURI:realTrackURI session:nil callback:^(NSError *error, id track) {
            if (error == nil) {
                [weakSelf.delegate nowPlayingChangedTo:track];
            } else {
                NSLog(@"Error getting track %@ ", error.localizedDescription);
            }
        }];
        [self receivedRemoveTrack:trackURI];
    }
}

- (void)connectionTerminated:(Connection *)connection {
    [self.delegate connectionTerminated];
}

- (void)connectionEstablished:(Connection *)connection {
    [self.delegate connectionReady];
}

@end
