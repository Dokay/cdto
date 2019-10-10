//
//  main.m
//  cd to ...
//
//  Created by James Tuley on 10/9/19.
//  Copyright © 2019 Jay Tuley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ScriptingBridge/ScriptingBridge.h>

#import "Finder.h"
#import "Terminal.h"

NSUInteger linesOfHistory(TerminalTab* tab) {
   NSString* hist = [[tab history] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return [[hist componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] count];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        FinderApplication* finder = [SBApplication applicationWithBundleIdentifier:@"com.apple.Finder"];
        
        TerminalApplication* terminal = [SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
                
        FinderItem *target = [(NSArray*)[[finder selection] get] firstObject];
        FinderFinderWindow* findWin = [[finder FinderWindows] objectAtLocation:@1];
        findWin = [[finder FinderWindows] objectWithID:[NSNumber numberWithInteger: findWin.id]];
        if (target == nil){
            target = [[findWin target] get];
        }
        
        if ([[target kind] isEqualToString:@"Alias"]){
            target = (FinderItem*)[(FinderAliasFile*)target originalItem];
        }
        
        NSString* fileUrl = [target URL];
        if(fileUrl != nil && ![fileUrl hasSuffix:@"/"]){
            fileUrl = [fileUrl stringByDeletingLastPathComponent];
        }
        
        NSURL* url = [NSURL URLWithString:fileUrl];
        if (url != nil){
            TerminalWindow* win = nil;
            if ([[terminal windows] count] == 1){
                //get front most and then reference by id
                win = [[terminal windows] objectAtLocation:@1];
                win = [[terminal windows] objectWithID: [NSNumber numberWithInteger:win.id]];
            }
            [terminal open:@[url]];
            //get front most and then reference by id
            TerminalWindow* newWin = [[terminal windows] objectAtLocation:@1];
            newWin = [[terminal windows] objectWithID: [NSNumber numberWithInteger:newWin.id]];
            TerminalTab* newTab = [[newWin tabs] objectAtLocation:@1];
            
            NSString* setName = [[NSUserDefaults standardUserDefaults] stringForKey:@"cdto-new-window-setting"];
            if(setName != nil && ![setName isEqualToString:@""]) { //setting set
                          NSString* setName = @"Grass";
                          TerminalSettingsSet* chosenSet = nil;
                          for (TerminalSettingsSet *set in [terminal settingsSets]) {
                              if([[set name] isEqualToString:setName]){
                                  chosenSet = set;
                              }
                          }
                          if(chosenSet != nil){
                              newTab.currentSettings = chosenSet;
                          }
                      }
            
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"cdto-close-default-window"]){ //close first launch window
                if([[win tabs] count] == 1){
                    TerminalTab* tab = [[win tabs]objectAtLocation:@1];
                    if(![tab busy]){
                        //if history has same number of lines as new window
                        // assume automatically opened new window, and close it
                        NSUInteger oldTabLines = linesOfHistory(tab);
                        while([newTab busy]){
                            [NSThread sleepForTimeInterval:0.1f];
                        }
                        NSUInteger newTabLines = linesOfHistory(newTab);
                        if(oldTabLines == newTabLines){
                            [win closeSaving:TerminalSaveOptionsNo savingIn:nil];
                        }
                    }
                }
            }
            
          
            [terminal activate];
        }
    }
}
