use strict;
use warnings;
use utf8;
use File::Spec;
use Plack::Builder;
use Amon2::Lite;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use App::ModulePlusPlus;

our $VERSION = '0.01';

__PACKAGE__->load_plugins('DBI');

sub config {
    my $c = shift;
    +{
        'DBI' => [
            "dbi:mysql:database=modulePlusPlus",
            'root',
            $ENV{MYSQL_ROOT_PASS} || '',
            +{
                mysql_enable_utf8 => 1
            },
        ],
    }
}

get '/' => sub {
    my $c = shift;
    return $c->render('index.tt');
};

post '/find' => sub {
    my $c = shift;

    my $module_name = $c->req->param('module_name');

    my ($all_users, $does_exist) = App::ModulePlusPlus::fetch_users($c, $module_name);

    unless ($does_exist) {
        my $not_found = "$module_name does not exist.";
        return $c->create_response(
            404,
            [
                'Content-Type'   => 'text/plain; charset=UTF-8',
                'Content-Length' => length($not_found),
            ],
            $not_found,
        );
    }

    my @users_exclude_anonymous = grep { $_ ne '---' } @$all_users;

    my $num_of_anonymous = scalar @$all_users - scalar @users_exclude_anonymous;
    @users_exclude_anonymous = sort { $a cmp $b } @users_exclude_anonymous;

    my $users = join(',', @users_exclude_anonymous);
    $users .= ',' if $users;
    $users .= "and $num_of_anonymous anonymous users";

    return $c->create_response(
        200,
        [
            'Content-Type'   => 'text/plain; charset=UTF-8',
            'Content-Length' => length($users)
        ],
        $users
    );
};

builder {
    enable "Plack::Middleware::Static",  path => qr{^/static}, root => "$FindBin::Bin";
    __PACKAGE__->to_app();
};

__DATA__

@@ index.tt
<!doctype html>
<html>
<head>
    <meta charst="utf-8">
    <title>Module++</title>
    <meta name="viewport" content="width=device-width, initial-scale=0.5">
    <script type="text/javascript" src="[% uri_for('/static/js/jquery-2.0.3.min.js') %]"></script>
    <script type="text/javascript" src="[% uri_for('/static/js/underscore-min.js') %]"></script>
    <script type="text/javascript" src="[% uri_for('/static/js/main.js') %]"></script>
    <link rel="stylesheet" href="[% uri_for('/static/css/base.css') %]">
</head>
<body>
    <div class="container">
        <header><h1>Module++</h1></header>
        <section>
            <form method="post" action="/find" id="ModuleNameForm">
                <div id="ModuleName">
                    <input type="text" name="module_name" size="20" placeholder="Moose" required />
                </div><button type="submit" id="SubmitBtn"><i class="icon-search"></i></button>
            </form>
            <div id="Loading"></div>
            <ul id="UserList"></ul>
        </section>
    </div>
    <footer>Powered by <a href="http://amon.64p.org">Amon2::Lite</a></footer>
</body>
</html>
