//
//  OpenAudioFile.m
//  PositionalSoundRotateSource
//
//  Created by Panayotis Matsinopoulos on 7/8/21.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CheckError.h"

ExtAudioFileRef OpenAudioFile(const char *fileName) {
  CFStringRef cfFileName = CFStringCreateWithCString(kCFAllocatorDefault,
                                                  fileName,
                                                  CFStringGetSystemEncoding());
  CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                       cfFileName,
                                                       kCFURLPOSIXPathStyle,
                                                       false);
  ExtAudioFileRef extAudioFile;
  CheckError(ExtAudioFileOpenURL(fileURL,
                                 &extAudioFile),
             "opening the ext audio file");
  
  CFRelease(cfFileName);
  CFRelease(fileURL);
  
  return extAudioFile;
}
