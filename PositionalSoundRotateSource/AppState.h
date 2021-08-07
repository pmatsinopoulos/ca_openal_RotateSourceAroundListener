//
//  MyLoopPlayer.h
//  PositionalSoundRotateSource
//
//  Created by Panayotis Matsinopoulos on 6/8/21.
//

#ifndef AppState_h
#define AppState_h

#include <AudioToolbox/AudioToolbox.h>

typedef struct _AppState {
  AudioStreamBasicDescription dataFormat;
  
  // this is the buffer that we will fill in from the
  // the audio file and we will finally give to the OpenAL Source
  UInt16 *sampleBuffer;
  
  UInt32 bufferSizeBytes;
  
  ALuint buffers[1];
  ALuint sources[1];
  
  double duration;
} AppState;

#endif /* AppState_h */
