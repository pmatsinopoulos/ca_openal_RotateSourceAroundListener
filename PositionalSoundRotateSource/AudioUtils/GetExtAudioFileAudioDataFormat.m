//
//  GetExtAudioFileAudioDataFormat.m
//  PositionalSoundRotateSource
//
//  Created by Panayotis Matsinopoulos on 7/8/21.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CheckError.h"

AudioStreamBasicDescription GetExtAudioFileAudioDataFormat(ExtAudioFileRef extAudioFile) {
  AudioStreamBasicDescription inputDataFormat = {0};
  UInt32 propSize = sizeof(inputDataFormat);
  CheckError(ExtAudioFileGetProperty(extAudioFile,
                                     kExtAudioFileProperty_FileDataFormat,
                                     &propSize,
                                     &inputDataFormat),
             "Getting the input data format from audio file");
  return inputDataFormat;
}
