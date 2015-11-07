//
//  CreateServerTableViewController.m
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "CreateServerTableViewController.h"

@interface CreateServerTableViewController () <UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spotifyLoadIndicator;
@property (weak, nonatomic) IBOutlet UITextField *partyNameTextBox;
@property SpotifyAuthenticator* spotifyAuthenticator;
@property BOOL loggedIn;
@property SPTUser* user;

-(void) hideSpotifyLoadIndicator;
-(void) showSpotifyLoadIndicator;

@end

@implementation CreateServerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString* partyNameDefault = [[[NSArray alloc] initWithObjects:[UIDevice currentDevice].name, @"'s party", nil] componentsJoinedByString:@""];
    self.partyNameTextBox.placeholder = partyNameDefault;
    self.spotifyAuthenticator = [[SpotifyAuthenticator alloc] initWithViewController:self];
    self.spotifyAuthenticator.delegate = self;
    self.loggedIn = NO;
    self.tableView.delegate = self;
    
    [self.loginButton setTitle:@"Sign in" forState:UIControlStateNormal];
    
    [self hideSpotifyLoadIndicator];
    [self.spotifyAuthenticator restoreOldSessionIfValidOtherwiseClearIt];
    self.user = nil;
}

- (void)dealloc
{
    self.spotifyAuthenticator.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row == 1) {
        [self loginButtonPressed:nil];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (IBAction)loginButtonPressed:(id)sender {
    if (self.loggedIn) {
        [self logout];
    } else {
        [self.spotifyAuthenticator displayLoginOverlay];
    }
}

-(void) logout {
    [self.spotifyAuthenticator logout];
    
    self.usernameLabel.text = @"Not signed in";
    [self.loginButton setTitle:@"Sign in" forState:UIControlStateNormal];
    self.loggedIn = NO;
}

#pragma mark - SpotifyAuthenticatorDelegate

- (void)spotifyAuthenticatorStartedLoading: (SpotifyAuthenticator*)spotifyAuthenticator; {
    [self showSpotifyLoadIndicator];
}

-(void) showSpotifyLoadIndicator {
    [self.spotifyLoadIndicator startAnimating];
    self.loginButton.enabled = NO;
    self.usernameLabel.hidden = YES;
}

-(void) hideSpotifyLoadIndicator {
    [self.spotifyLoadIndicator stopAnimating];
    self.loginButton.enabled = YES;
    self.usernameLabel.hidden = NO;
}

- (void)spotifyAuthenticator: (SpotifyAuthenticator*)spotifyAuthenticator loggedInWithSession: (SPTSession*)session andUser: (SPTUser*)user {
    self.user = user;
    
    if (user.displayName != nil) {
        self.usernameLabel.text = user.displayName;
    } else {
        self.usernameLabel.text = user.canonicalUserName;
    }
    
    [self.loginButton setTitle:@"Logout" forState:UIControlStateNormal];
    self.loggedIn = YES;
    [self hideSpotifyLoadIndicator];
}

- (void)spotifyAuthenticator: (SpotifyAuthenticator*)spotifyAuthenticator failedToLoginWithError: (NSError *)error {
    self.usernameLabel.text = @"Not signed in";
    [self.loginButton setTitle:@"Sign in" forState:UIControlStateNormal];
    self.loggedIn = NO;
    
    NSString* message = [NSString stringWithFormat:@"The following error occured while signing in: %@", error.localizedDescription];
    [self createAndDisplayAlertWithTitle:@"Error" andMessage:message];
}


#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"CreateServerToCreatedServer"]) {
        if (self.loggedIn == NO) {
            [self createAndDisplayAlertWithTitle:@"Can't create" andMessage:@"You have to sign in to Spotify to create a server"];
            return NO;
        }
        
        if (self.user == nil) {
            assert(NO);
            return NO;
        }
        
        if (self.user.product != SPTProductPremium) {
            [self createAndDisplayAlertWithTitle:@"Can't create" andMessage:@"You have to use a premium Spotify account to create a server"];
            return NO;
        }
    }
    
    return YES;
}

- (void) createAndDisplayAlertWithTitle: (NSString*) title andMessage: (NSString*) message {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message: message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier  isEqualToString: @"CreateServerToCreatedServer"]) {
        NSString* name = self.partyNameTextBox.text;
        if ([name isEqualToString:@""]) {
            name = self.partyNameTextBox.placeholder;
        }

        MusicVoterServer* musicVoterServer = [[MusicVoterServer alloc] initWithName:name];
        
        CreatedServerTableViewController* createdServerViewController = [segue destinationViewController];
        [createdServerViewController setMusicVoterServer:musicVoterServer];
    }
}

@end
