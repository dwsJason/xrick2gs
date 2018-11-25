/*
 * xrick/src/syssnd.c
 *
 * Copyright (C) 1998-2002 BigOrno (bigorno@bigorno.net). All rights reserved.
 *
 * The use and distribution terms for this software are contained in the file
 * named README, which can be found in the root of this distribution. By
 * using this software in any fashion, you are agreeing to be bound by the
 * terms of this license.
 *
 * You must not remove this notice, or any other, from this software.
 */

#ifdef IIGS
#pragma noroot
#endif

#ifndef IIGS
#include <SDL.h>
#endif
#include <stdlib.h>
#include <memory.h>

#include "config.h"

#ifdef ENABLE_SOUND

#include "system.h"
#include "game.h"
#include "syssnd.h"
#include "debug.h"
#include "data.h"

segment "system";


#ifdef IIGS

char* pNtpDriver = NULL;
char* pNtpSong   = NULL;

extern char ntpplayer_lz4;
extern char sfx_lz4;
extern char sfx_lz5;

void SetAudioBank(char bankNo);
void NTPstop(void);
void NTPplay(int bPlayOnce);
int NTPprepare(void* pNTPData);
void mraLoadBank(char* pAudioBank);
void mraPlay(U8 sfxNo);

void
syssnd_init(void)
{
	U32* handle = NULL;
	printf("syssnd_init\n");
	// Allocate a buffer for the NTPAudio Driver
	// and to place the various NTP songs that will play
	printf("Alloc NTPDriver\n");
	handle = (U32*)NewHandle(0x10000, userid(), 0xC014, 0);  
	if (toolerror())
	{
		printf("Unable to allocate Audio Driver Mem\n");
		printf("Game can't run\n");
		sys_sleep(5000);  // Wait 5 seconds
		exit(1);
	}
	printf("SUCCESS\n");

	pNtpDriver = (char*)*handle;
	pNtpSong   = pNtpDriver + 0x8000;

	//printf("%p\n", pNtpDriver );
	//printf("%p\n", pNtpSong );
	
	//--- Take Advantage of the 64k bank we just
	//    Allocated, as a temp buffer to get our
	//    SFX loaded into the DOC

	printf("Decompress SFX %p\n", &sfx_lz4); // Force this to be linked in
	printf("Decompress SFX %p\n", &sfx_lz5); // Force this to be linked in
	LZ4_Unpack(pNtpDriver, &sfx_lz4);

	printf("Load SFX into the DOC\n");
	mraLoadBank(pNtpDriver);

	printf("Decompress NTP Driver\n");
	LZ4_Unpack(pNtpDriver, &ntpplayer_lz4);
	printf("Decompress samerica\n");
	LZ4_Unpack(pNtpSong, &samerica_lz4);

	printf("SetAudioBank\n");
	SetAudioBank( (*handle)>>16 );

	#if 0
	printf("NTPprepare\n");

	if (NTPprepare(pNtpSong))
	{
		printf("NTPprepare failed\n");
	}
	else
	{
		printf("NTPplay\n");
		NTPplay(0);
	}
	#endif
	
}

/*
 * Shutdown
 */
void
syssnd_shutdown(void)
{
	printf("syssnd_shutdown\n");
  //if (!isAudioActive) return;
  //isAudioActive = FALSE;
}

/*
 * Toggle mute
 *
 * When muted, sounds are still managed but not sent to the dsp, hence
 * it is possible to un-mute at any time.
 */
void
syssnd_toggleMute(void)
{
	printf("syssnd_toggleMute\n");
}

void
syssnd_vol(S8 d)
{
	printf("syssnd_vol: %d\n", d);
}

/*
 * Play a sound
 *
 * loop: number of times the sound should be played, -1 to loop forever
 * returns: channel number, or -1 if none was available
 *
 * NOTE if sound is already playing, simply reset it (i.e. can not have
 * twice the same sound playing -- tends to become noisy when too many
 * bad guys die at the same time).
 */
S8
syssnd_play(sound_t sound, S8 loop)
{
	//printf("syssnd_play\n");
	if ((sound >= 0) && (sound<SND_MAX))
	{
		mraPlay((U8)sound);
	}
	return 0;
}

/*
 * Pause
 *
 * pause: TRUE or FALSE
 * clear: TRUE to cleanup all sounds and make sure we start from scratch
 */
void
syssnd_pause(U8 pause, U8 clear)
{
	printf("syssnd_pause\n");
}

/*
 * Stop a channel
 */
void
syssnd_stopchan(S8 chan)
{
	printf("syssnd_stopchan\n");
}

/*
 * Stop a sound
 */
void
syssnd_stopsound(sound_t sound)
{
	printf("syssnd_stopsound\n");
}

/*
 * See if a sound is playing
 */
int
syssnd_isplaying(sound_t sound)
{
	printf("syssnd_isplaying\n");
	return 0;
}


/*
 * Stops all channels.
 */
void
syssnd_stopall(void)
{
	printf("syssnd_stopall\n");
}

/*
 *
 */
void
syssnd_free(sound_t s)
{
	printf("syssnd_free\n");
}


#else

#define ADJVOL(S) (((S)*sndVol)/SDL_MIX_MAXVOLUME)

static U8 isAudioActive = FALSE;
static channel_t channel[SYSSND_MIXCHANNELS];

static U8 sndVol = SDL_MIX_MAXVOLUME;  /* internal volume */
static U8 sndUVol = SYSSND_MAXVOL;  /* user-selected volume */
static U8 sndMute = FALSE;  /* mute flag */

static SDL_mutex *sndlock;

/*
 * prototypes
 */
static int sdlRWops_open(SDL_RWops *context, char *name);
static int sdlRWops_seek(SDL_RWops *context, int offset, int whence);
static int sdlRWops_read(SDL_RWops *context, void *ptr, int size, int maxnum);
static int sdlRWops_write(SDL_RWops *context, const void *ptr, int size, int num);
static int sdlRWops_close(SDL_RWops *context);
static void end_channel(U8);

/*
 * Callback -- this is also where all sound mixing is done
 *
 * Note: it may not be that much a good idea to do all the mixing here ; it
 * may be more efficient to mix samples every frame, or maybe everytime a
 * new sound is sent to be played. I don't know.
 */
void syssnd_callback(UNUSED(void *userdata), U8 *stream, int len)
{
  U8 c;
  S16 s;
  U32 i;

  SDL_mutexP(sndlock);

  for (i = 0; i < (U32)len; i++) {
    s = 0;
    for (c = 0; c < SYSSND_MIXCHANNELS; c++) {
      if (channel[c].loop != 0) {  /* channel is active */
	if (channel[c].len > 0) {  /* not ending */
	  s += ADJVOL(*channel[c].buf - 0x80);
	  channel[c].buf++;
	  channel[c].len--;
	}
	else {  /* ending */
	  if (channel[c].loop > 0) channel[c].loop--;
	  if (channel[c].loop) {  /* just loop */
	    IFDEBUG_AUDIO2(sys_printf("xrick/audio: channel %d - loop\n", c););
	    channel[c].buf = channel[c].snd->buf;
	    channel[c].len = channel[c].snd->len;
	    s += ADJVOL(*channel[c].buf - 0x80);
	    channel[c].buf++;
	    channel[c].len--;
	  }
	  else {  /* end for real */
	    IFDEBUG_AUDIO2(sys_printf("xrick/audio: channel %d - end\n", c););
	    end_channel(c);
	  }
	}
      }
    }
    if (sndMute)
      stream[i] = 0x80;
    else {
      s += 0x80;
      if (s > 0xff) s = 0xff;
      if (s < 0x00) s = 0x00;
      stream[i] = (U8)s;
    }
  }

  memcpy(stream, stream, len);

  SDL_mutexV(sndlock);
}

static void
end_channel(U8 c)
{
	channel[c].loop = 0;
	if (channel[c].snd->dispose)
		syssnd_free(channel[c].snd);
	channel[c].snd = NULL;
}

void
syssnd_init(void)
{
  SDL_AudioSpec desired, obtained;
  U16 c;

  if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0) {
    IFDEBUG_AUDIO(
      sys_printf("xrick/audio: can not initialize audio subsystem\n");
      );
    return;
  }

  desired.freq = SYSSND_FREQ;
  desired.format = AUDIO_U8;
  desired.channels = SYSSND_CHANNELS;
  desired.samples = SYSSND_MIXSAMPLES;
  desired.callback = syssnd_callback;
  desired.userdata = NULL;

  if (SDL_OpenAudio(&desired, &obtained) < 0) {
    IFDEBUG_AUDIO(
      sys_printf("xrick/audio: can not open audio (%s)\n", SDL_GetError());
      );
    return;
  }

  sndlock = SDL_CreateMutex();
  if (sndlock == NULL) {
    IFDEBUG_AUDIO(sys_printf("xrick/audio: can not create lock\n"););
    SDL_CloseAudio();
    return;
  }

  if (sysarg_args_vol != 0) {
    sndUVol = sysarg_args_vol;
    sndVol = SDL_MIX_MAXVOLUME * sndUVol / SYSSND_MAXVOL;
  }

  for (c = 0; c < SYSSND_MIXCHANNELS; c++)
    channel[c].loop = 0;  /* deactivate */

	isAudioActive = TRUE;
	SDL_PauseAudio(0);
}

/*
 * Shutdown
 */
void
syssnd_shutdown(void)
{
  if (!isAudioActive) return;

  SDL_CloseAudio();
  SDL_DestroyMutex(sndlock);
  isAudioActive = FALSE;
}

/*
 * Toggle mute
 *
 * When muted, sounds are still managed but not sent to the dsp, hence
 * it is possible to un-mute at any time.
 */
void
syssnd_toggleMute(void)
{
  SDL_mutexP(sndlock);
  sndMute = !sndMute;
  SDL_mutexV(sndlock);
}

void
syssnd_vol(S8 d)
{
  if ((d < 0 && sndUVol > 0) ||
      (d > 0 && sndUVol < SYSSND_MAXVOL)) {
    sndUVol += d;
    SDL_mutexP(sndlock);
    sndVol = SDL_MIX_MAXVOLUME * sndUVol / SYSSND_MAXVOL;
    SDL_mutexV(sndlock);
  }
}

/*
 * Play a sound
 *
 * loop: number of times the sound should be played, -1 to loop forever
 * returns: channel number, or -1 if none was available
 *
 * NOTE if sound is already playing, simply reset it (i.e. can not have
 * twice the same sound playing -- tends to become noisy when too many
 * bad guys die at the same time).
 */
S8
syssnd_play(sound_t *sound, S8 loop)
{
  S8 c;

  if (!isAudioActive) return -1;
  if (sound == NULL) return -1;

  c = 0;
  SDL_mutexP(sndlock);
  while ((channel[c].snd != sound || channel[c].loop == 0) &&
	 channel[c].loop != 0 &&
	 c < SYSSND_MIXCHANNELS)
    c++;
  if (c == SYSSND_MIXCHANNELS)
    c = -1;

  IFDEBUG_AUDIO(
    if (channel[c].snd == sound && channel[c].loop != 0)
      sys_printf("xrick/sound: already playing %s on channel %d - resetting\n",
		 sound->name, c);
    else if (c >= 0)
      sys_printf("xrick/sound: playing %s on channel %d\n", sound->name, c);
    );

  if (c >= 0) {
    channel[c].loop = loop;
    channel[c].snd = sound;
    channel[c].buf = sound->buf;
    channel[c].len = sound->len;
  }
  SDL_mutexV(sndlock);

  return c;
}

/*
 * Pause
 *
 * pause: TRUE or FALSE
 * clear: TRUE to cleanup all sounds and make sure we start from scratch
 */
void
syssnd_pause(U8 pause, U8 clear)
{
  U8 c;

  if (!isAudioActive) return;

  if (clear == TRUE) {
    SDL_mutexP(sndlock);
    for (c = 0; c < SYSSND_MIXCHANNELS; c++)
      channel[c].loop = 0;
    SDL_mutexV(sndlock);
  }

  if (pause == TRUE)
    SDL_PauseAudio(1);
  else
    SDL_PauseAudio(0);
}

/*
 * Stop a channel
 */
void
syssnd_stopchan(S8 chan)
{
  if (chan < 0 || chan > SYSSND_MIXCHANNELS)
    return;

  SDL_mutexP(sndlock);
  if (channel[chan].snd) end_channel(chan);
  SDL_mutexV(sndlock);
}

/*
 * Stop a sound
 */
void
syssnd_stopsound(sound_t *sound)
{
	U8 i;

	if (!sound) return;

	SDL_mutexP(sndlock);
	for (i = 0; i < SYSSND_MIXCHANNELS; i++)
		if (channel[i].snd == sound) end_channel(i);
	SDL_mutexV(sndlock);
}

/*
 * See if a sound is playing
 */
int
syssnd_isplaying(sound_t *sound)
{
	U8 i, playing;

	playing = 0;
	SDL_mutexP(sndlock);
	for (i = 0; i < SYSSND_MIXCHANNELS; i++)
		if (channel[i].snd == sound) playing = 1;
	SDL_mutexV(sndlock);
	return playing;
}


/*
 * Stops all channels.
 */
void
syssnd_stopall(void)
{
	U8 i;

	SDL_mutexP(sndlock);
	for (i = 0; i < SYSSND_MIXCHANNELS; i++)
		if (channel[i].snd) end_channel(i);
	SDL_mutexV(sndlock);
}

/*
 * Load a sound.
 */
sound_t *
syssnd_load(char *name)
{
	sound_t *s;
	SDL_RWops *context;
	SDL_AudioSpec audiospec;

	/* alloc context */
	context = malloc(sizeof(SDL_RWops));
	context->seek = sdlRWops_seek;
	context->read = sdlRWops_read;
	context->write = sdlRWops_write;
	context->close = sdlRWops_close;

	/* open */
	if (sdlRWops_open(context, name) == -1)
		return NULL;

	/* alloc sound */
	s = malloc(sizeof(sound_t));
#ifdef DEBUG
	s->name = malloc(strlen(name) + 1);
	strncpy(s->name, name, strlen(name) + 1);
#endif

	/* read */
	/* second param == 1 -> close source once read */
	if (!SDL_LoadWAV_RW(context, 1, &audiospec, &(s->buf), &(s->len)))
	{
		free(s);
		return NULL;
	}

	s->dispose = FALSE;

	return s;
}

/*
 *
 */
void
syssnd_free(sound_t *s)
{
	if (!s) return;
	if (s->buf) SDL_FreeWAV(s->buf);
	s->buf = NULL;
	s->len = 0;
}

/*
 *
 */
static int
sdlRWops_open(SDL_RWops *context, char *name)
{
	data_file_t *f;

	f = data_file_open(name);
	if (!f) return -1;
	context->hidden.unknown.data1 = (void *)f;

	return 0;
}

static int
sdlRWops_seek(SDL_RWops *context, int offset, int whence)
{
	return data_file_seek((data_file_t *)(context->hidden.unknown.data1), offset, whence);
}

static int
sdlRWops_read(SDL_RWops *context, void *ptr, int size, int maxnum)
{
	return data_file_read((data_file_t *)(context->hidden.unknown.data1), ptr, size, maxnum);
}

static int
sdlRWops_write(SDL_RWops *context, const void *ptr, int size, int num)
{
	/* not implemented */
	return -1;
}

static int
sdlRWops_close(SDL_RWops *context)
{
	if (context)
	{
		data_file_close((data_file_t *)(context->hidden.unknown.data1));
		free(context);
	}
	return 0;
}

#endif /* IIGS */
#endif /* ENABLE_SOUND */

/* eof */

