# vim:set ft= ts=4 sw=4 et fdm=marker:

use lib 'lib';
use Test::Nginx::Socket;

#worker_connections(1014);
#master_process_enabled(1);
#log_level('warn');

repeat_each(2);
#repeat_each(10000);

plan tests => blocks() * repeat_each() * 3 - repeat_each() * 1;

#no_diff();
#no_long_string();

run_tests();

__DATA__

=== TEST 1: set response content-type header
--- config
    location /read {
        echo "Hi";
        header_filter_by_lua '
            ngx.header.content_type = "text/my-plain";
        ';

    }
--- request
GET /read
--- response_headers
Content-Type: text/my-plain
--- response_body
Hi



=== TEST 2: lua code run failed
--- config
    location /read {
        echo "Hi";
        header_filter_by_lua '
            ngx.header.content_length = "text/my-plain";
        ';
    }
--- request
GET /read
--- error_code
--- response_body



=== TEST 3: use variable generated by content phrase
--- config
   location /read {
        set $strvar '1';
        content_by_lua '
            ngx.var.strvar = "127.0.0.1:8080";
            ngx.say("Hi");
        ';
        header_filter_by_lua '
            ngx.header.uid = ngx.var.strvar;
        ';
    }
--- request
GET /read
--- response_headers
uid: 127.0.0.1:8080
--- response_body
Hi



=== TEST 4: use variable generated by content phrase for HEAD
--- config
   location /read {
        set $strvar '1';
        content_by_lua '
            ngx.var.strvar = "127.0.0.1:8080";
            ngx.say("Hi");
        ';
        header_filter_by_lua '
            ngx.header.uid = ngx.var.strvar;
        ';
    }
--- request
HEAD /read
--- response_headers
uid: 127.0.0.1:8080
--- response_body



=== TEST 5: use variable generated by content phrase for HTTP 1.0
--- config
   location /read {
        set $strvar '1';
        content_by_lua '
            ngx.var.strvar = "127.0.0.1:8080";
            ngx.say("Hi");
        ';
        header_filter_by_lua '
            ngx.header.uid = ngx.var.strvar;
        ';

    }
--- request
GET /read HTTP/1.0
--- response_headers
uid: 127.0.0.1:8080
--- response_body
Hi



=== TEST 6: use capture and header_filter_by
--- config
   location /sub {
        content_by_lua '
            ngx.say("Hi");
        ';
        header_filter_by_lua '
            ngx.header.uid = "sub";
        ';
    }

    location /parent {
        content_by_lua '
            local res = ngx.location.capture("/sub")
            if res.status == 200 then
                ngx.say(res.header.uid)
            else
                ngx.say("parent")
            end
        ';
        header_filter_by_lua '
            ngx.header.uid = "parent";
        ';
    }

--- request
GET /parent
--- response_headers
uid: parent
--- response_body
sub



=== TEST 7: overriding ctx
--- config
    location /lua {
        content_by_lua '
            ngx.ctx.foo = 32;
            ngx.say(ngx.ctx.foo)
        ';
        header_filter_by_lua '
            ngx.ctx.foo = ngx.ctx.foo + 1;
            ngx.header.uid = ngx.ctx.foo;
        ';
    }
--- request
GET /lua
--- response_headers
uid: 33
--- response_body
32



=== TEST 8: use req
--- config
    location /lua {
        content_by_lua '
            ngx.say("Hi");
        ';

        header_filter_by_lua '
            local str = "";
            local args = ngx.req.get_uri_args()
            for key, val in pairs(args) do
                if type(val) == "table" then
                    str = str .. table.concat(val, ", ")
                else
                    str = str .. ":" .. val
                end
            end

            ngx.header.uid = str;
        ';
    }
--- request
GET /lua?a=1&b=2
--- response_headers
uid: :1:2
--- response_body
Hi



=== TEST 9: use ngx md5 function
--- config
    location /lua {
        content_by_lua '
            ngx.say("Hi");
        ';
        header_filter_by_lua '
            ngx.header.uid = ngx.md5("Hi");
        ';
    }
--- request
GET /lua
--- response_headers
uid: c1a5298f939e87e8f962a5edfc206918
--- response_body
Hi

