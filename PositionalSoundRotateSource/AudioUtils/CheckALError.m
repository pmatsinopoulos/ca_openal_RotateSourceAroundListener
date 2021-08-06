//
//  CheckALError.m
//  PositionalSoundRotateSource
//
//  Created by Panayotis Matsinopoulos on 6/8/21.
//

#import <Foundation/Foundation.h>
#import <OpenAL/OpenAL.h>

void CheckALError(const char *operation) {
  ALenum alErr = alGetError();
  
  if (alErr == AL_NO_ERROR) {
    return;
  }
  
  char *errFormat = NULL;
  switch (alErr) {
    case AL_INVALID_NAME:
      errFormat = "OpenAL Error: %s (AL_INVALID_NAME)";
      break;
    case AL_INVALID_VALUE:
      errFormat = "OpenAL Error: %s (AL_INVALID_VALUE)";
      break;
    case AL_INVALID_ENUM:
      errFormat = "OpenAL Error: %s (AL_INVALID_ENUM)";
      break;
    case AL_INVALID_OPERATION:
      errFormat = "OpenAL Error: %s (AL_INVALID_OPERATION)";
      break;
    case AL_OUT_OF_MEMORY:
      errFormat = "OpenAL Error: %s (AL_OUT_OF_MEMORY)";
      break;
    default:
      errFormat = "OpenAL Error: %s Unknown";
      break;
  }
  fprintf(stderr, errFormat, operation);
  exit(1);
}
