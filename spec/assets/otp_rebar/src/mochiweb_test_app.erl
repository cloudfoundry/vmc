%% @author Mochi Media <dev@mochimedia.com>
%% @copyright mochiweb_test Mochi Media <dev@mochimedia.com>

%% @doc Callbacks for the mochiweb_test application.

-module(mochiweb_test_app).
-author("Mochi Media <dev@mochimedia.com>").

-behaviour(application).
-export([start/2,stop/1]).


%% @spec start(_Type, _StartArgs) -> ServerRet
%% @doc application start callback for mochiweb_test.
start(_Type, _StartArgs) ->
    mochiweb_test_deps:ensure(),
    mochiweb_test_sup:start_link().

%% @spec stop(_State) -> ServerRet
%% @doc application stop callback for mochiweb_test.
stop(_State) ->
    ok.
