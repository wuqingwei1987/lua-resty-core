# vim:set ft= ts=4 sw=4 et fdm=marker:
use lib 'lib';
use Test::Nginx::Socket::Lua::Stream;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (blocks() * 6);

my $pwd = cwd();

our $StreamConfig = <<_EOC_;
    lua_package_path "$pwd/lib/?.lua;../lua-resty-lrucache/lib/?.lua;;";
    init_by_lua_block {
        -- local verbose = true
        local verbose = false
        local outfile = "$Test::Nginx::Util::ErrLogFile"
        -- local outfile = "/tmp/v.log"
        if verbose then
            local dump = require "jit.dump"
            dump.on(nil, outfile)
        else
            local v = require "jit.v"
            v.on(outfile)
        end

        require "resty.core"
    }
_EOC_

no_long_string();
check_accum_error_log();
run_tests();

__DATA__

=== TEST 1: ngx.now()
--- stream_config eval: $::StreamConfig
--- stream_server_config
    content_by_lua_block {
        local t
        for i = 1, 500 do
            t = ngx.now()
        end
        ngx.sleep(0.10)
        local elapsed = ngx.now() - t
        ngx.say(t > 1399867351)
        ngx.say(">= 0.099: ", elapsed >= 0.099)
        ngx.say("< 0.11: ", elapsed < 0.11)
        -- ngx.say(t, " ", elapsed)
    }
--- stream_response
true
>= 0.099: true
< 0.11: true

--- error_log eval
qr/\[TRACE\s+\d+ content_by_lua\(nginx\.conf:\d+\):3 loop\]/
--- no_error_log
[error]
bad argument type
stitch



=== TEST 2: ngx.time()
--- stream_config eval: $::StreamConfig
--- stream_server_config
    content_by_lua_block {
        local t
        for i = 1, 500 do
            t = ngx.time()
        end
        ngx.say(t > 1400960598)
        local diff = os.time() - t
        ngx.say(diff <= 1)
    }
--- stream_response
true
true

--- error_log eval
qr/\[TRACE\s+\d+ content_by_lua\(nginx\.conf:\d+\):3 loop\]/
--- no_error_log
[error]
bad argument type
stitch



=== TEST 3: ngx.update_time()
--- stream_config eval: $::StreamConfig
--- stream_server_config
    content_by_lua_block {
        local start = ngx.now()
        for _ = 1, 1e5 do
            ngx.update_time()
        end
        ngx.say(ngx.now() - start > 0)
    }
--- stream_response
true
--- error_log eval
qr/\[TRACE\s+\d+ content_by_lua\(nginx\.conf:\d+\):3 loop\]/
--- no_error_log
[error]
bad argument type
stitch



=== TEST 4: ngx.today()
--- stream_config eval: $::StreamConfig
--- stream_server_config
    content_by_lua_block {
        local t
        for i = 1, 500 do
            t = ngx.today()
        end
        ngx.say(t)
    }
--- stream_response_like: ^\d{4}-\d{2}-\d{2}
--- error_log eval
qr/\[TRACE\s+\d+ content_by_lua\(nginx\.conf:\d+\):3 loop\]/
--- no_error_log
[error]
bad argument type
stitch



=== TEST 5: ngx.localtime()
--- stream_config eval: $::StreamConfig
--- stream_server_config
    content_by_lua_block {
        local t
        for i = 1, 500 do
            t = ngx.localtime()
        end
        ngx.say(t)
    }
--- stream_response_like: ^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$
--- error_log eval
qr/\[TRACE\s+\d+ content_by_lua\(nginx\.conf:\d+\):3 loop\]/
--- no_error_log
[error]
bad argument type
stitch



=== TEST 6: ngx.utctime()
--- stream_config eval: $::StreamConfig
--- stream_server_config
    content_by_lua_block {
        local t
        for i = 1, 500 do
            t = ngx.utctime()
        end
        ngx.say(t)
    }
--- stream_response_like: ^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$
--- error_log eval
qr/\[TRACE\s+\d+ content_by_lua\(nginx\.conf:\d+\):3 loop\]/
--- no_error_log
[error]
bad argument type
stitch
