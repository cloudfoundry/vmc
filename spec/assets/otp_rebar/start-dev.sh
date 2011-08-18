#!/bin/sh
# NOTE: mustache templates need \ because they are not awesome.
exec erl -pa ebin edit deps/*/ebin -boot start_sasl \
    -sname mochiweb_test_dev \
    -s mochiweb_test \
    -s reloader +B -noconsole
