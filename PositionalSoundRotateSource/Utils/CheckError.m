//
//  CheckError.m
//  PositionalSoundRotateSource
//
//  Created by Panayotis Matsinopoulos on 6/8/21.
//

#import <Foundation/Foundation.h>

#import <ctype.h>
#import <stdio.h>

void CheckError(OSStatus error, const char *operation) {
  if (error == noErr) {
    return;
  }
  
  char errorString[20];
  *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error); // we have 4 bytes and we put them in Big-endian ordering. 1st byte the biggest
  if (isprint(errorString[1]) && isprint(errorString[2]) &&
      isprint(errorString[3]) && isprint(errorString[4])) {
    errorString[0] = errorString[5] = '\'';
    errorString[6] = '\0';
  } else {
    sprintf(errorString, "%d", (int) error);
  }
  NSLog(@"Error: %s (%s)\n", operation, errorString);
  exit(1);
}
