/*
 File: ParserChoiceViewController.m
 Abstract: Provides an interface for choosing and running one of the two available parsers.
 Version: 1.3
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "ParserChoiceViewController.h"
#import "SongsViewController.h"
#import "LibXMLParser.h"
#import "CocoaXMLParser.h"
#import "TBXMLParser.h"
#import "TouchXMLParser.h"
#import "KissXMLParser.h"
#import "TinyXMLParser.h"
#import "GDataXMLParser.h"
#import "LibXMLDOMParser.h"
#import "RaptureXMLParser.h"

@implementation ParserChoiceViewController

@synthesize parserSelection;


- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Set the background for the main view to match the table view.
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    // Set an initial selection.
    self.parserSelection = [NSIndexPath indexPathForRow:0 inSection:0];
    
    [self setTitle:@"Parsers"];
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStyleDone target:self action:@selector(startParserButtonPressed:)]];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (SongsViewController *)songsViewController {
    if (songsViewController == nil) {
        songsViewController = [[SongsViewController alloc] initWithStyle:UITableViewStylePlain];
    }
    return songsViewController;
}

- (UINavigationController *)songsNavigationController {
    if (songsNavigationController == nil) {
        songsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.songsViewController];
    }
    return songsNavigationController;
}

- (void)startParserButtonPressed:(id)sender {
    [self.navigationController presentViewController:self.songsNavigationController animated:YES completion:nil];
    //     [self.navigationController pushViewController:self.songsViewController animated:YES];
    [self.songsViewController parseWithParserType:self.parserSelection.row];
}

- (NSUInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSUInteger)section {
    return 9;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * const kCellIdentifier = @"MyCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = [CocoaXMLParser parserName];
            break;
        case 1:
            cell.textLabel.text = [LibXMLParser parserName];
            break;
        case 2:
            cell.textLabel.text = [TBXMLParser parserName];
            break;
        case 3:
            cell.textLabel.text = [TouchXMLParser parserName];
            break;
        case 4:
            cell.textLabel.text = [KissXMLParser parserName];
            break;
        case 5:
            cell.textLabel.text = [TinyXMLParser parserName];
            break;
        case 6:
            cell.textLabel.text = [GDataXMLParser parserName];
            break;
        case 7:
            cell.textLabel.text = [LibXMLDOMParser parserName];
            break;
        case 8:
            cell.textLabel.text = [RaptureXMLParser parserName];
            break;
    }
    cell.accessoryType = ([indexPath isEqual:parserSelection]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.parserSelection = indexPath;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
}

@end
