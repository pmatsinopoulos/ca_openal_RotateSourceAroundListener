//
//  GetNumberOfFramesInFile.h
//  PositionalSoundRotateSource
//
//  Created by Panayotis Matsinopoulos on 7/8/21.
//

#ifndef GetNumberOfFramesInFile_h
#define GetNumberOfFramesInFile_h

#import <AudioToolbox/AudioToolbox.h>

SInt64 GetNumberOfFramesInFile(ExtAudioFileRef extAudioFile);

#endif /* GetNumberOfFramesInFile_h */
