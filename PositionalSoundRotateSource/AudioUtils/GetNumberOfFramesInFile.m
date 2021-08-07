//
//  GetNumberOfFramesInFile.m
//  PositionalSoundRotateSource
//
//  Created by Panayotis Matsinopoulos on 7/8/21.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CheckError.h"

SInt64 GetNumberOfFramesInFile(ExtAudioFileRef extAudioFile) {
  SInt64 fileLengthFrames = 0;
  UInt32 propSize = sizeof(fileLengthFrames);
  CheckError(ExtAudioFileGetProperty(extAudioFile,
                                     kExtAudioFileProperty_FileLengthFrames,
                                     &propSize,
                                     &fileLengthFrames),
             "Getting the number of frames in the file");
  return fileLengthFrames;
}
