//
//  main.m
//  PositionalSoundRotateSource
//
//  Created by Panayotis Matsinopoulos on 6/8/21.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <OpenAL/OpenAL.h>
#include "CheckError.h"
#include "CheckALError.h"
#include "AppState.h"

#define ORBIT_SPEED 1

OSStatus LoadAudioDataIntoBuffer(AppState *appState, const char *fileName) {
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
  
  memset((void *)&(appState->dataFormat), 0, sizeof(appState->dataFormat));
  appState->dataFormat.mFormatID = kAudioFormatLinearPCM;
  appState->dataFormat.mFramesPerPacket = 1;
  appState->dataFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
  appState->dataFormat.mBitsPerChannel = 16;
  appState->dataFormat.mChannelsPerFrame = 1; // mono
  appState->dataFormat.mBytesPerFrame = appState->dataFormat.mBitsPerChannel * appState->dataFormat.mChannelsPerFrame / 8;
  appState->dataFormat.mBytesPerPacket = appState->dataFormat.mBytesPerFrame * appState->dataFormat.mFramesPerPacket;
  appState->dataFormat.mSampleRate = 44100.0;

  CheckError(ExtAudioFileSetProperty(extAudioFile,
                                     kExtAudioFileProperty_ClientDataFormat,
                                     sizeof(appState->dataFormat),
                                     &(appState->dataFormat)),
             "Setting the client data format on the ext audio file");
  
  SInt64 fileLengthFrames;
  UInt32 propSize = sizeof(fileLengthFrames);
  CheckError(ExtAudioFileGetProperty(extAudioFile,
                                     kExtAudioFileProperty_FileLengthFrames,
                                     &propSize,
                                     &fileLengthFrames),
             "Getting the number of frames in the file");
  
  AudioStreamBasicDescription inputDataFormat;
  propSize = sizeof(inputDataFormat);
  CheckError(ExtAudioFileGetProperty(extAudioFile,
                                     kExtAudioFileProperty_FileDataFormat,
                                     &propSize,
                                     &inputDataFormat),
             "Getting the input data format from audio file");
  
  SInt64 framesToPutInBuffer = fileLengthFrames * appState->dataFormat.mSampleRate / inputDataFormat.mSampleRate;
  
  appState->bufferSizeBytes = framesToPutInBuffer * appState->dataFormat.mBytesPerFrame;
  appState->duration = framesToPutInBuffer / appState->dataFormat.mSampleRate;

  appState->sampleBuffer = malloc(appState->bufferSizeBytes);

  // This is a temporary structure that will basically be used as an interface
  // to the ExtAudioFileRead(). Its mBuffers[0].mData pointer will point to the
  // part of the appState->sampleBuffer we want to put data in when reading from
  // ExtAudioFileRead().
  AudioBufferList abl;
  abl.mNumberBuffers = 1;
  abl.mBuffers[0].mNumberChannels = appState->dataFormat.mChannelsPerFrame;
    
  UInt32 totalFramesRead = 0;
  UInt32 framesToRead = 0;
  do {
    framesToRead = framesToPutInBuffer - totalFramesRead;
    abl.mBuffers[0].mData = appState->sampleBuffer + totalFramesRead * appState->dataFormat.mBytesPerFrame;
    abl.mBuffers[0].mDataByteSize = framesToRead * appState->dataFormat.mBytesPerFrame;
    
    CheckError(ExtAudioFileRead(extAudioFile,
                                &framesToRead,
                                &abl),
               "Reading data from the audio file");
    totalFramesRead += framesToRead;
  } while(totalFramesRead < framesToPutInBuffer);
  
  CheckError(ExtAudioFileDispose(extAudioFile), "Disposing the ext audio file");
  CFRelease(cfFileName);
  return noErr;
}

void UpdateSourceLocation(AppState *appState) {
  double theta = fmod(CFAbsoluteTimeGetCurrent() * ORBIT_SPEED, M_PI * 2);
  ALfloat x = 3 * cos(theta);
  ALfloat y = 0.5 * sin(theta);
  ALfloat z = 1.0 * sin(theta);
  
  alSource3f(appState->sources[0], AL_POSITION, x, y, z);
  
  CheckALError("updating source lodation");
  
  return;
}

ALCdevice *OpenDevice() {
  ALCdevice *alDevice = alcOpenDevice(NULL);
  CheckALError("opening the defaul AL device");
  return alDevice;
}

ALCcontext * CreateContext(ALCdevice *alDevice) {
  ALCcontext *alContext = alcCreateContext(alDevice, 0);
  CheckALError("creating AL context");
  
  alcMakeContextCurrent(alContext);
  CheckALError("making the context current");
  
  return alContext;
}

void CreateSource(AppState *appState) {
  alGenSources(1, appState->sources);

  alSourcef(appState->sources[0],
            AL_GAIN,
            AL_MAX_GAIN);
  CheckALError("setting the AL property for gain");
  
  UpdateSourceLocation(appState);
}

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSLog(@"Starting...");
    
    AppState appState;
    
    CheckError(LoadAudioDataIntoBuffer(&appState, argv[1]), "Loading Audio Data Into Buffer");
    
    ALCdevice *alDevice = OpenDevice();
    
    ALCcontext *alContext = CreateContext(alDevice);
    
    CreateSource(&appState);
    
    alGenBuffers(1, appState.buffers);
    CheckALError("generating AL buffers");
    
    alBufferData(appState.buffers[0],
                 AL_FORMAT_MONO16,
                 appState.sampleBuffer,
                 appState.bufferSizeBytes,
                 appState.dataFormat.mSampleRate);
    CheckALError("giving data to the AL buffer");
    free(appState.sampleBuffer);
    appState.sampleBuffer = NULL;
    
    
    alSourcei(appState.sources[0], AL_BUFFER, appState.buffers[0]);
    CheckALError("setting the buffer to the source");
    
    alListener3f(AL_POSITION, 0.0, 0.0, 0.0);
    CheckALError("setting the listener position");
    
    alSourcePlay(appState.sources[0]);
    CheckALError("starting the source");
    
    printf("Playing ... \n");
    time_t startTime = time(NULL);
    
    do {
      UpdateSourceLocation(&appState);
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    } while(difftime(time(NULL), startTime) < (appState.duration + 0.5));
    
    alSourceStop(appState.sources[0]);
    CheckALError("stopping the source");
    
    alDeleteSources(1, appState.sources);
    alDeleteBuffers(1, appState.buffers);
    alcDestroyContext(alContext);
    alcCloseDevice(alDevice);
    
    NSLog(@"Bye");
  }
  return 0;
}
