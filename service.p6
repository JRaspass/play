use Config::TOML;
use Cro::HTTP::Log::File;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::WebApp::Template;

$*ERR.out-buffer = $*OUT.out-buffer = False;

template-location 'views/', :compile-all;

my %examples = from-toml(:file<examples.toml>);
my $welcome  = %examples<welcome>:delete;
my @examples = %examples.pairs.sort: { .value.<name> };

my $server = Cro::HTTP::Server.new(
    :after(Cro::HTTP::Log::File.new)
    :host<0.0.0.0>
    :port<1337>
    :application(route {
        get -> { template 'code.crotmp', $welcome }

        get -> *@path { static 'static', @path }

        get -> 'about' { template 'about.crotmp' }

        get -> 'examples' { template 'examples.crotmp', { :@examples } }
        get -> 'examples', $id {
            with %examples{$id} {
                template 'code.crotmp', .<code>;
            }
            else {
                not-found;
            }
        }

        post -> :$Accept is header {
            my %content;

            # TODO Can we pass the request.body promise to $proc.bind-stdin?
            request-body-text -> $code {
                my $proc = Proc::Async.new: :w, 'run-perl';

                react {
                    # TODO Can we build the JSON directly from the supply?
                    whenever $proc.Supply { %content<output> ~= $_ }

                    whenever $proc.start {
                        %content<exitcode signal> = .exitcode, .signal;
                        done;
                    }

                    whenever $proc.print: $code { $proc.close-stdin }

                    whenever Promise.in: 5 { $proc.kill: SIGKILL }
                }
            }

            if $Accept ~~ /«'application/json'»/ {
                # Strip ANSI escape sequences.
                s:g/\x1b\[<[0..9;]>*<[A..Za..z]>// with %content<output>;

                content 'application/json', %content;
            }
            else {
                content 'text/plain', %content<output>;
            }
        }
    })
);

$server.start;

say 'Listening…';

react whenever signal(SIGINT) {
    say 'Stopping…';

    $server.stop;

    done;
}
