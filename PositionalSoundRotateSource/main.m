//
//  main.m
//  PositionalSoundRotateSource
//
//  Created by Panayotis Matsinopoulos on 6/8/21.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <OpenAL/OpenAL.h>
#import "CheckError.h"
#import "CheckALError.h"
#import "AppState.h"
#import "OpenAudioFile.h"
#import "GetNumberOfFramesInFile.h"
#import "GetExtAudioFileAudioDataFormat.h"

#define ORBIT_SPEED 1

AudioStreamBasicDescription SpecifyAudioFormatToConverTo(ExtAudioFileRef extAudioFile) {
  AudioStreamBasicDescription dataFormat;
  
  memset((void *)&(dataFormat), 0, sizeof(dataFormat));
  dataFormat.mFormatID = kAudioFormatLinearPCM;
  dataFormat.mFramesPerPacket = 1;
  dataFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
  dataFormat.mBitsPerChannel = 16;
  dataFormat.mChannelsPerFrame = 1; // mono
  dataFormat.mBytesPerFrame = dataFormat.mBitsPerChannel * dataFormat.mChannelsPerFrame / 8;
  dataFormat.mBytesPerPacket = dataFormat.mBytesPerFrame * dataFormat.mFramesPerPacket;
  dataFormat.mSampleRate = 44100.0;

  CheckError(ExtAudioFileSetProperty(extAudioFile,
                                     kExtAudioFileProperty_ClientDataFormat,
                                     sizeof(dataFormat),
                                     &(dataFormat)),
             "Setting the client data format on the ext audio file");
  return dataFormat;
}

void ReadAudioDataAndStoreInTempBuffer(ExtAudioFileRef extAudioFile,
                                       AudioStreamBasicDescription convertToDataFormat,
                                       SInt64 framesToPutInBuffer,
                                       UInt8 **oTempBuffer,
                                       UInt32 *oTempBufferSize) {
  *oTempBufferSize = framesToPutInBuffer * convertToDataFormat.mBytesPerFrame;
  (*oTempBuffer) = malloc(*oTempBufferSize);

  // This is a temporary structure that will basically be used as an interface
  // to the ExtAudioFileRead(). Its mBuffers[0].mData pointer will point to the
  // part of the appState->sampleBuffer we want to put data in when reading from
  // ExtAudioFileRead().
  AudioBufferList abl;
  abl.mNumberBuffers = 1;
  abl.mBuffers[0].mNumberChannels = convertToDataFormat.mChannelsPerFrame;
    
  UInt32 totalFramesRead = 0;
  UInt32 framesToRead = 0;
  do {
    framesToRead = framesToPutInBuffer - totalFramesRead;
    abl.mBuffers[0].mData = (*oTempBuffer) + totalFramesRead * convertToDataFormat.mBytesPerFrame;
    abl.mBuffers[0].mDataByteSize = framesToRead * convertToDataFormat.mBytesPerFrame;
    
    CheckError(ExtAudioFileRead(extAudioFile,
                                &framesToRead,
                                &abl),
               "Reading data from the audio file");
    totalFramesRead += framesToRead;
  } while(totalFramesRead < framesToPutInBuffer);
}

void CopyTempBufferDataToALBuffer(AppState *appState,
                                  UInt8 *tempBuffer,
                                  UInt32 tempBufferSize,
                                  AudioStreamBasicDescription convertToDataFormat) {
  alBufferData(appState->buffers[0],
               AL_FORMAT_MONO16,
               tempBuffer,
               tempBufferSize,
               convertToDataFormat.mSampleRate);
  CheckALError("giving data to the AL buffer");
}

void ReleaseTempBuffer(UInt8 **oTempBuffer) {
  free(*oTempBuffer);
  oTempBuffer = NULL;
}

OSStatus LoadAudioDataIntoBuffer(AppState *appState, const char *fileName) {
  ExtAudioFileRef extAudioFile = OpenAudioFile(fileName);
    
  AudioStreamBasicDescription inputDataFormat = GetExtAudioFileAudioDataFormat(extAudioFile);
  
  SInt64 fileLengthFrames = GetNumberOfFramesInFile(extAudioFile);
  
  AudioStreamBasicDescription convertToDataFormat = SpecifyAudioFormatToConverTo(extAudioFile);
  
  SInt64 framesToPutInBuffer = fileLengthFrames * convertToDataFormat.mSampleRate / inputDataFormat.mSampleRate;
  
  appState->duration = framesToPutInBuffer / convertToDataFormat.mSampleRate;

  // this is the buffer that we will fill in from the
  // the audio file and we will finally give to the OpenAL Source.
  // OpenAL Source will copy data from this buffer.
  UInt8 *tempBuffer;
  UInt32 tempBufferSize;
  
  ReadAudioDataAndStoreInTempBuffer(extAudioFile,
                                    convertToDataFormat,
                                    framesToPutInBuffer,
                                    &tempBuffer,
                                    &tempBufferSize);
  
  // Close the input audio file. We don't need it any more.
  CheckError(ExtAudioFileDispose(extAudioFile), "Disposing the ext audio file");
    
  CopyTempBufferDataToALBuffer(appState,
                               tempBuffer,
                               tempBufferSize,
                               convertToDataFormat);
  
  ReleaseTempBuffer(&tempBuffer);
  
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

ALCdevice *OpenDevice(void) {
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

void CreateAndFillBuffer(AppState *appState, const char *fileName) {
  alGenBuffers(1, appState->buffers);
  CheckALError("generating AL buffers");

  CheckError(LoadAudioDataIntoBuffer(appState, fileName), "Loading Audio Data Into Buffer");
}

void LinkBufferToSource(AppState *appState) {
  alSourcei(appState->sources[0], AL_BUFFER, appState->buffers[0]);
  CheckALError("setting the buffer to the source");
}

void PositionListenerInScene(void) {
  alListener3f(AL_POSITION, 0.0, 0.0, 0.0);
  CheckALError("setting the listener position");
}

void StartSource(AppState *appState) {
  alSourcePlay(appState->sources[0]);
  CheckALError("starting the source");
}

void StopSource(AppState *appState) {
  alSourceStop(appState->sources[0]);
  CheckALError("stopping the source");
}

void ReleaseResources(AppState *appState, ALCdevice *alDevice, ALCcontext *alContext) {
  alDeleteSources(1, appState->sources);
  alDeleteBuffers(1, appState->buffers);
  alcDestroyContext(alContext);
  alcCloseDevice(alDevice);
}

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSLog(@"Starting...");
    
    AppState appState;
    
    ALCdevice *alDevice = OpenDevice();
    
    ALCcontext *alContext = CreateContext(alDevice);
    
    CreateSource(&appState);
            
    CreateAndFillBuffer(&appState, argv[1]);
    
    LinkBufferToSource(&appState);
    
    PositionListenerInScene();
    
    StartSource(&appState);
    
    printf("Playing ... \n");
    time_t startTime = time(NULL);
    
    do {
      UpdateSourceLocation(&appState);
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    } while(difftime(time(NULL), startTime) < (appState.duration + 0.5));
    
    StopSource(&appState);
    
    ReleaseResources(&appState, alDevice, alContext);
    
    NSLog(@"Bye");
  }
  return 0;
}
