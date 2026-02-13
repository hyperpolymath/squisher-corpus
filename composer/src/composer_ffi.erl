%% SPDX-License-Identifier: PMPL-1.0-or-later
%% Erlang FFI for composer shell and file operations.
-module(composer_ffi).
-export([shell_exec/1, write_file/2]).

-spec shell_exec(binary()) -> {ok, binary()} | {error, binary()}.
shell_exec(Command) ->
    try
        Result = os:cmd(binary_to_list(Command)),
        {ok, list_to_binary(Result)}
    catch
        _:Reason ->
            {error, list_to_binary(io_lib:format("~p", [Reason]))}
    end.

-spec write_file(binary(), binary()) -> {ok, binary()} | {error, binary()}.
write_file(Path, Content) ->
    case file:write_file(binary_to_list(Path), Content) of
        ok -> {ok, Path};
        {error, Reason} ->
            {error, list_to_binary(io_lib:format("~p", [Reason]))}
    end.
