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

@interface MusicVoterServer : NSObject <BonjourServerDelegate,SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, ConnectionDelegate>

@property (nonatomic, weak) id delegate;

@property (readonly) NSMutableArray* voteTracks;
@property (readonly) BOOL isPaused;
-(NSString*) getName;
@property (readonly) BOOL published;
-(BOOL) getIsPlaying;
@property BOOL allowSameSongName;

- (id)initWithName: (NSString*) name;
-(void) publish;

-(void) stopPlaying;
-(void) continueOrStartPlaying;
-(void) pausePlaying;
-(void) playNextTrack;

-(void) addItemsFromPlaylist: (SPTPartialPlaylist*) partialPlaylist;

@end

@protocol MusicVoterServerDelegate <NSObject>

-(void)nowPlayingChanged:(SPTTrack*) newTrack;
-(void)trackListChanged;
-(void)didPublish;

@end