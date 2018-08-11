/*
	bctypes.h

	Budcat Standard Types
	
	(c) 2001-2006  Budcat Creations, LLC. 

*/

#ifndef _bctypes_h
#define _bctypes_h

typedef	signed char			i8;
typedef unsigned char		u8;
typedef signed short		i16;
typedef unsigned short		u16;
typedef signed long			i32;
typedef unsigned long		u32;

#if !_MSVC
typedef signed long long	i64;
typedef unsigned long long	u64;

//typedef int                 i128 __attribute__ ((__mode__(__TI__)));   // 128 bit integer            
//typedef int                 s128 __attribute__ ((__mode__(__TI__)));   // 128 bit signed integer     
//typedef unsigned int        u128 __attribute__ ((__mode__(__TI__)));   // 128 bit unsigned integer   
#endif

typedef	i32					bool;

typedef float				f32;
typedef float				r32;
typedef double				f64;
typedef double				r64;


#define false (0)
#define true (!false)

#define null (0)

// Odd Types
typedef union {
//  u128       ul128;
  u64        ul64[2];
  u32        ui32[4];
} QWdata;


#endif // _bctypes_h

// EOF - bctypes.h

