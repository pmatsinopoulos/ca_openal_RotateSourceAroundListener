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
#include "MyLoopPlayer.h"

#define ORBIT_SPEED 1

OSStatus LoadLoopIntoBuffer(MyLoopPlayer *player, const char *fileName) {
  CFStringRef cfFileName = CFStringCreateWithCString(kCFAllocatorDefault,
                                                  fileName,
                                                  CFStringGetSystemEncoding());
  CFURLRef loopFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                       cfFileName,
                                                       kCFURLPOSIXPathStyle,
                                                       false);
  ExtAudioFileRef extAudioFile;
  CheckError(ExtAudioFileOpenURL(loopFileURL,
                                 &extAudioFile),
             "opening the ext audio file");
  
  memset((void *)&(player->dataFormat), 0, sizeof(player->dataFormat));
  player->dataFormat.mFormatID = kAudioFormatLinearPCM;
  player->dataFormat.mFramesPerPacket = 1;
  player->dataFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
  player->dataFormat.mBitsPerChannel = 16;
  player->dataFormat.mChannelsPerFrame = 1; // mono
  player->dataFormat.mBytesPerFrame = player->dataFormat.mBitsPerChannel * player->dataFormat.mChannelsPerFrame / 8;
  player->dataFormat.mBytesPerPacket = player->dataFormat.mBytesPerFrame * player->dataFormat.mFramesPerPacket;
  player->dataFormat.mSampleRate = 44100.0;

  CheckError(ExtAudioFileSetProperty(extAudioFile,
                                     kExtAudioFileProperty_ClientDataFormat,
                                     sizeof(player->dataFormat),
                                     &(player->dataFormat)),
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
  
  SInt64 framesToPutInBuffer = fileLengthFrames * player->dataFormat.mSampleRate / inputDataFormat.mSampleRate;
  
  player->bufferSizeBytes = framesToPutInBuffer * player->dataFormat.mBytesPerFrame;
  player->duration = framesToPutInBuffer / player->dataFormat.mSampleRate;

  player->sampleBuffer = malloc(player->bufferSizeBytes);

  // This is a temporary structure that will basically be used as an interface
  // to the ExtAudioFileRead(). Its mBuffers[0].mData pointer will point to the
  // part of the player->sampleBuffer we want to put data in when reading from
  // ExtAudioFileRead().
  AudioBufferList abl;
  abl.mNumberBuffers = 1;
  abl.mBuffers[0].mNumberChannels = player->dataFormat.mChannelsPerFrame;
    
  UInt32 totalFramesRead = 0;
  UInt32 framesToRead = 0;
  do {
    framesToRead = framesToPutInBuffer - totalFramesRead;
    abl.mBuffers[0].mData = player->sampleBuffer + totalFramesRead * player->dataFormat.mBytesPerFrame;
    abl.mBuffers[0].mDataByteSize = framesToRead * player->dataFormat.mBytesPerFrame;
    
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

void UpdateSourceLocation(MyLoopPlayer *player) {
  double theta = fmod(CFAbsoluteTimeGetCurrent() * ORBIT_SPEED, M_PI * 2);
  ALfloat x = 3 * cos(theta);
  ALfloat y = 0.5 * sin(theta);
  ALfloat z = 1.0 * sin(theta);
  
  alSource3f(player->sources[0], AL_POSITION, x, y, z);
  
  CheckALError("updating source lodation");
  
  return;
}

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSLog(@"Starting...");
    
    MyLoopPlayer player;
    
    CheckError(LoadLoopIntoBuffer(&player, argv[1]), "Loading Loop Into Buffer");
    
    ALCdevice *alDevice = alcOpenDevice(NULL);
    CheckALError("opening the defaul AL device");
    
    ALCcontext *alContext = alcCreateContext(alDevice, 0);
    CheckALError("creating AL context");
    
    alcMakeContextCurrent(alContext);
    CheckALError("making the context current");
    
    ALuint buffers[1];
    alGenBuffers(1, buffers);
    CheckALError("generating AL buffers");
    
    alBufferData(buffers[0],
                 AL_FORMAT_MONO16,
                 player.sampleBuffer,
                 player.bufferSizeBytes,
                 player.dataFormat.mSampleRate);
    CheckALError("giving data to the AL buffer");
    free(player.sampleBuffer);
    player.sampleBuffer = NULL;
    
    alGenSources(1, player.sources);

    alSourcef(player.sources[0],
              AL_GAIN,
              AL_MAX_GAIN);
    CheckALError("setting the AL property for gain");
    
    UpdateSourceLocation(&player);
    
    alSourcei(player.sources[0], AL_BUFFER, buffers[0]);
    CheckALError("setting the buffer to the source");
    
    alListener3f(AL_POSITION, 0.0, 0.0, 0.0);
    CheckALError("setting the listener position");
    
    alSourcePlay(player.sources[0]);
    CheckALError("starting the source");
    
    printf("Playing ... \n");
    time_t startTime = time(NULL);
    
    do {
      UpdateSourceLocation(&player);
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    } while(difftime(time(NULL), startTime) < (player.duration + 0.5));
    
    alSourceStop(player.sources[0]);
    CheckALError("stopping the source");
    
    alDeleteSources(1, player.sources);
    alDeleteBuffers(1, buffers);
    alcDestroyContext(alContext);
    alcCloseDevice(alDevice);
    
    NSLog(@"Bye");
  }
  return 0;
}
