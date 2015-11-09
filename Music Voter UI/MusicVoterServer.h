//
//  MusicVoterServer.h
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Spotify/Spotify.h>
#import "BonjourServer.h"
#import "VoteTrack.h"
#import "MusicVoterConnectionProtocol.h"

@interface MusicVoterServer : NSObject <BonjourServerDelegate,SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, ConnectionDelegate, MusicVoterConnection>

@property (nonatomic, weak) id<MusicVoterConnectionDelegate> delegate;

@property (readonly) NSMutableArray* voteTracks;
-(NSString*) getName;
@property (readonly) BOOL published;
@property BOOL allowSameSongName;

- (id)initWithName: (NSString*) name;
-(void) publish;

@property (readonly) BOOL isPaused;
-(BOOL) getIsPlaying;
-(void) stopPlaying;
-(void) continueOrStartPlaying;
-(void) pausePlaying;
-(void) playNextTrack;

-(void) addItemsFromPlaylist: (SPTPartialPlaylist*) partialPlaylist;

@end