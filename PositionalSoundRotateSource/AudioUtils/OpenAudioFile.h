//
//  OpenAudioFile.h
//  PositionalSoundRotateSource
//
//  Created by Panayotis Matsinopoulos on 7/8/21.
//

#ifndef OpenAudioFile_h
#define OpenAudioFile_h

#import <AudioToolbox/AudioToolbox.h>

ExtAudioFileRef OpenAudioFile(const char *fileName);

#endif /* OpenAudioFile_h */
