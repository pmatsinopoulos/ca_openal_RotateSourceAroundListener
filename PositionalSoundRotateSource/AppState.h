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
  ALuint buffers[1];
  ALuint sources[1];
  
  double duration;
} AppState;

#endif /* AppState_h */
