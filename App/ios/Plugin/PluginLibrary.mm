//
//  PluginLibrary.mm
//  TemplateApp
//
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PluginLibrary.h"
#import <Skillz/Skillz.h>
#include <CoronaRuntime.h>
#import <UIKit/UIKit.h>

// ----------------------------------------------------------------------------

class PluginLibrary
{
	public:
		typedef PluginLibrary Self;

	public:
		static const char kName[];
		static const char kEvent[];

	protected:
		PluginLibrary();

	public:
		bool Initialize( CoronaLuaRef listener );

	public:
		CoronaLuaRef GetListener() const { return fListener; }

	public:
		static int Open( lua_State *L );

	protected:
		static int Finalizer( lua_State *L );

	public:
		static Self *ToLibrary( lua_State *L );

	public:
		static int init( lua_State *L );
		static int show( lua_State *L );
        static int randomNumber( lua_State *L);
        static int updateScore( lua_State *L);
        static int endMatch( lua_State *L);

	private:
		CoronaLuaRef fListener;
};

// ----------------------------------------------------------------------------

// This corresponds to the name of the library, e.g. [Lua] require "plugin.library"
const char PluginLibrary::kName[] = "plugin.Skillz";

// This corresponds to the event name, e.g. [Lua] event.name
const char PluginLibrary::kEvent[] = "skillzEvent";

@interface LocalSkillzDelegate : NSObject<SkillzDelegate>
    @property (nonatomic) Corona::Lua::Ref listenerRef;
    @property (nonatomic, assign) lua_State *L;
    @property (nonatomic) SkillzOrientation orientation;
@end


@implementation LocalSkillzDelegate
- (void)tournamentWillBegin:(NSDictionary *)gameParameters
              withMatchInfo:(SKZMatchInfo *)matchInfo
{
    CoronaLuaNewEvent( self.L, "skillzEvent");
    
    lua_pushstring( self.L, "skillzEvent" );        // All events are Lua tables
    lua_setfield( self.L, -2, "name" );      // that have a 'name' property
    
    lua_pushstring( self.L, "willBegin");
    lua_setfield( self.L, -2, "phase" );
    
    lua_pushstring( self.L, [matchInfo.description cStringUsingEncoding:10]);
    lua_setfield( self.L, -2, "description" );
    
    lua_pushstring( self.L, [matchInfo.name cStringUsingEncoding:10]);
    lua_setfield( self.L, -2, "name" );
    
    lua_pushboolean(self.L, matchInfo.isCash);
    lua_setfield( self.L, -2, "isCash" );
    
    lua_pushboolean(self.L, NO);
    lua_setfield( self.L, -2, "isError" );
    
    
    CoronaLuaDispatchEvent( self.L, self.listenerRef, 0 );
    
}

- (void)skillzWillExit
{
    CoronaLuaNewEvent( self.L, "skillzEvent");
    
    lua_pushstring( self.L, "skillzEvent" );        // All events are Lua tables
    lua_setfield( self.L, -2, "name" );      // that have a 'name' property
    
    lua_pushstring( self.L, "exit");
    lua_setfield( self.L, -2, "phase" );
    
    lua_pushboolean(self.L, NO);
    lua_setfield( self.L, -2, "isError" );
    
    
    CoronaLuaDispatchEvent( self.L, self.listenerRef, 0 );
}

- (SkillzOrientation)preferredSkillzInterfaceOrientation
{
    // return SkillzPortrait for portrait based applications
    // return SkillzLandscape for landscape based applications
    return _orientation;
}


@end


static LocalSkillzDelegate* skillzDelegate = [[LocalSkillzDelegate alloc] init];

PluginLibrary::PluginLibrary()
:	fListener( NULL )
{
}

bool
PluginLibrary::Initialize( CoronaLuaRef listener )
{
	// Can only initialize listener once
	bool result = ( NULL == fListener );

	if ( result )
	{
		fListener = listener;
	}

	return result;
}

int
PluginLibrary::Open( lua_State *L )
{
	// Register __gc callback
	const char kMetatableName[] = __FILE__; // Globally unique string to prevent collision
	CoronaLuaInitializeGCMetatable( L, kMetatableName, Finalizer );

	// Functions in library
	const luaL_Reg kVTable[] =
	{
		{ "init", init },
		{ "show", show },
        { "randomNumber", randomNumber },
        { "updateScore", updateScore },
        { "endMatch", endMatch },
		{ NULL, NULL }
	};

	// Set library as upvalue for each library function
	Self *library = new Self;
	CoronaLuaPushUserdata( L, library, kMetatableName );

	luaL_openlib( L, kName, kVTable, 1 ); // leave "library" on top of stack

	return 1;
}

int
PluginLibrary::Finalizer( lua_State *L )
{
	Self *library = (Self *)CoronaLuaToUserdata( L, 1 );

	CoronaLuaDeleteRef( L, library->GetListener() );

	delete library;

	return 0;
}

PluginLibrary *
PluginLibrary::ToLibrary( lua_State *L )
{
	// library is pushed as part of the closure
	Self *library = (Self *)CoronaLuaToUserdata( L, lua_upvalueindex( 1 ) );
	return library;
}


int
PluginLibrary::init( lua_State *L )
{
    
    const char *key = nil;
    const char *orientation = "portrait";
    BOOL allowExit = YES;
    
	int listenerIndex = 1;

	if ( CoronaLuaIsListener( L, listenerIndex, kEvent ) )
	{
		Self *library = ToLibrary( L );

		CoronaLuaRef listener = CoronaLuaNewRef( L, listenerIndex );
		library->Initialize( listener );
        
        skillzDelegate.L = L;
        skillzDelegate.listenerRef = listener;
	}
    
    if ( lua_type( L, -1 ) == LUA_TTABLE )
    {
        lua_getfield( L, -1, "key" );
        if ( lua_type( L, -1 ) == LUA_TSTRING )
        {
            key = lua_tostring( L, -1 );
        }
        lua_pop( L, 1 );
        
        lua_getfield( L, -1, "orientation" );
        if ( lua_type( L, -1 ) == LUA_TSTRING )
        {
            orientation = lua_tostring( L, -1 );
        }
        lua_pop( L, 1 );
        
        lua_getfield( L, -1, "allowExit" );
        if ( lua_type( L, -1 ) == LUA_TBOOLEAN )
        {
            allowExit = lua_toboolean( L, -1 );
        }
        lua_pop( L, 1 );
    }
    
    if (strcmp(orientation, "portrait") == 0) {
        skillzDelegate.orientation = SkillzPortrait;
    } else {
        skillzDelegate.orientation = SkillzLandscape;
    }
    
    [[Skillz skillzInstance] initWithGameId:[NSString stringWithUTF8String:key]
                                forDelegate: skillzDelegate
                            withEnvironment:SkillzProduction
                                  allowExit: allowExit];
    
	return 0;
}



int
PluginLibrary::show( lua_State *L )
{
    
    [[Skillz skillzInstance] launchSkillz];
    return 0;
}

int
PluginLibrary::randomNumber( lua_State *L )
{
    if (lua_type(L, 1) == LUA_TNUMBER && lua_type(L, 2) == LUA_TNUMBER) {
        NSUInteger randomNumber = [Skillz getRandomNumberWithMin: (NSUInteger)lua_tointeger(L, 1) andMax:(NSUInteger)lua_tointeger(L, 2)];
        
        //This does nothing as expected.
        lua_pushinteger( L, randomNumber );
        
        
    } else {
        lua_pushinteger( L, 0 );
        
    }
    
    return 1;

}

int
PluginLibrary::updateScore( lua_State *L )
{
    if ([[Skillz skillzInstance] tournamentIsInProgress]) {
        if (lua_type(L, 1) == LUA_TNUMBER) {
            [[Skillz skillzInstance] updatePlayersCurrentScore:[NSNumber numberWithLong:lua_tointeger(L, 1)]];
        }
        
    }
    
    return 0;
}


int
PluginLibrary::endMatch( lua_State *L )
{

    if ([[Skillz skillzInstance] tournamentIsInProgress]) {
        if (lua_type(L, 1) == LUA_TNUMBER) {
        [[Skillz skillzInstance] displayTournamentResultsWithScore:[NSNumber numberWithLong:lua_tointeger(L, 1)]
                                                    withCompletion:^{
                                                    }];
        }
    }

	return 0;
}

// ----------------------------------------------------------------------------

CORONA_EXPORT int luaopen_plugin_library( lua_State *L )
{
	return PluginLibrary::Open( L );
}
