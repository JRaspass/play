use Cro::HTTP::Log::File;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;

template-location 'views/', :compile-all;

my $application = route {
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
}

my @after = Cro::HTTP::Log::File.new: :errors($*ERR) :logs($*OUT);

( my $http = Cro::HTTP::Server.new: :1080port :@after :$application ).start;

say 'Listening…';

react whenever signal(SIGINT) {
    say 'Stopping…';

    $http.stop;

    done;
}
