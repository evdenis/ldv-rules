#ifndef _GENERATE_
#define _GENERATE_

#define func(decl_spec, name) \
   decl_spec int name ## 1( void ) { name ## 2(); name ## 3(); return -1; } EXPORT_SYMBOL( name ## 1 ); \
   decl_spec int name ## 2( void ) { name ## 1(); name ## 3(); return -1; } EXPORT_SYMBOL_GPL( name ## 2 ); \
   decl_spec int name ## 3( void ) { name ## 1(); name ## 2(); return -1; } EXPORT_SYMBOL_GPL_FUTURE( name ## 3 );

#define ifunc(decl_spec, name) \
   decl_spec int name ## 1( void ) { return -1; } EXPORT_SYMBOL( name ## 1 ); \
   decl_spec int name ## 2( void ) { return -1; } EXPORT_SYMBOL_GPL( name ## 2 ); \
   decl_spec int name ## 3( void ) { return -1; } EXPORT_SYMBOL_GPL_FUTURE( name ## 3 );

#define cfunc(name) \
   name ## 1(); \
   name ## 2(); \
   name ## 3();

#ifdef EXTERN
#define efunc(decl_spec, name) \
   extern int name ## 1( void );\
   extern int name ## 2( void );\
   extern int name ## 3( void );
#else
#define efunc(decl_spec, name) \
   decl_spec int name ## 1( void );\
   decl_spec int name ## 2( void );\
   decl_spec int name ## 3( void );
#endif

#define odecl(decl_spec, name) \
   decl_spec int name ## 1( void );\
   decl_spec int name ## 2( void );\
   decl_spec int name ## 3( void );

#endif
