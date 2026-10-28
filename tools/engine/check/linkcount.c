// LD_PRELOAD shim for tools/engine/check/native-ab.sh: counts glLinkProgram calls and times each link (with the status query
// that waits on it), one line per link: "<n> <program id> <ms>". It wraps dlsym, so it sees the glXGetProcAddressARB that
// Godot's GL loader (glad) resolves, and hands back a counting glLinkProgram. Linux, GLX only.
#define _GNU_SOURCE
#include <dlfcn.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
typedef void (*fn_t)(void);
typedef fn_t (*gpa_t)(const unsigned char *);
typedef void (*link_t)(unsigned int);
typedef void (*getprogiv_t)(unsigned int, unsigned int, int *);
static gpa_t real_gpa; static link_t real_link; static getprogiv_t real_getprogiv;
static FILE *out; static long n;
static double now(void){struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return t.tv_sec*1e3+t.tv_nsec/1e6;}
static void my_link(unsigned int p){
  double t0=now(); real_link(p);
  int st=0; if(real_getprogiv) real_getprogiv(p,0x8B82,&st); /* GL_LINK_STATUS: waits for the link */
  if(!out){const char*f=getenv("LINKCOUNT_OUT"); out=fopen(f?f:"/dev/stderr","w");}
  fprintf(out,"%ld %u %.3f\n",++n,p,now()-t0); fflush(out);
}
static fn_t my_gpa(const unsigned char *name){
  fn_t f=real_gpa(name);
  if(!strcmp((const char*)name,"glGetProgramiv")) real_getprogiv=(getprogiv_t)f;
  if(!strcmp((const char*)name,"glLinkProgram")){ real_link=(link_t)f; return (fn_t)my_link; }
  return f;
}
void *dlsym(void *h, const char *name){
  static void *(*real_dlsym)(void*,const char*);
  if(!real_dlsym) real_dlsym=dlvsym(RTLD_NEXT,"dlsym","GLIBC_2.34");
  if(!real_dlsym) real_dlsym=dlvsym(RTLD_NEXT,"dlsym","GLIBC_2.2.5");
  void *r=real_dlsym(h,name);
  if(r && (!strcmp(name,"glXGetProcAddressARB")||!strcmp(name,"glXGetProcAddress"))){ real_gpa=(gpa_t)r; return (void*)my_gpa; }
  return r;
}
