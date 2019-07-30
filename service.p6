use Cro::HTTP::Log::File;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;

$*ERR.out-buffer = $*OUT.out-buffer = False;

template-location 'views/', :compile-all;

# HTTP → HTTPS
my @servers = Cro::HTTP::Server.new(
    :host<0.0.0.0>
    :port<1080>
    :application(route {
        get -> *@ { redirect :permanent, request.uri.clone: :scheme<https> }
    })
);

@servers.push: Cro::HTTP::Server.new(
    :after(Cro::HTTP::Log::File.new)
    :host<0.0.0.0>
    :http<1.1>
    :port<1443>
    :tls({
        :certificate-file</tls/fullchain.cer>
        :private-key-file</tls/play-perl6.org.key>
        :ciphers<ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384>
    })
    :application(route {
        get ->         { template 'index.crotmp' }
        get -> 'about' { template 'about.crotmp' }
        get -> *@path  { static 'static', @path  }

        get -> 'snippets', Str $id where /^<[A..Za..z0..9_-]>+$/ {
            ...;
        }

        post -> 'run' {
            request-body-text -> $code {
                warn $code;
            };

            content 'application/json', { stdout => 'Hello, World!' };
        }

        post -> 'share' {
            ...;
        }
    })
);

@servers».start;

say 'Listening…';

react whenever signal(SIGINT) {
    say 'Stopping…';

    @servers».stop;

    done;
}
