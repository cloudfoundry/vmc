%% @author Mochi Media <dev@mochimedia.com>
%% @copyright 2010 Mochi Media <dev@mochimedia.com>

%% @doc mochiweb_test.

-module(mochiweb_test).
-author("Mochi Media <dev@mochimedia.com>").
-export([start/0, stop/0]).

ensure_started(App) ->
    case application:start(App) of
        ok ->
            ok;
        {error, {already_started, App}} ->
            ok
    end.


%% @spec start() -> ok
%% @doc Start the mochiweb_test server.
start() ->
    mochiweb_test_deps:ensure(),
    ensure_started(crypto),
    application:start(mochiweb_test).


%% @spec stop() -> ok
%% @doc Stop the mochiweb_test server.
stop() ->
    application:stop(mochiweb_test).
