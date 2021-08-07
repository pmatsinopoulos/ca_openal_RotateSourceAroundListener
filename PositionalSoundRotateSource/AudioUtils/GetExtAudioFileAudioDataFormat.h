//
//  GetExtAudioFileAudioDataFormat.h
//  PositionalSoundRotateSource
//
//  Created by Panayotis Matsinopoulos on 7/8/21.
//

#ifndef GetExtAudioFileAudioDataFormat_h
#define GetExtAudioFileAudioDataFormat_h

#import <AudioToolbox/AudioToolbox.h>

AudioStreamBasicDescription GetExtAudioFileAudioDataFormat(ExtAudioFileRef extAudioFile);

#endif /* GetExtAudioFileAudioDataFormat_h */
