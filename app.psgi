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

    my @all_users = @{App::ModulePlusPlus::fetch_users($c, $module_name)};
    my @users_exclude_anonymous = grep { $_ ne '---' } @all_users;

    my $num_of_anonymous = scalar @all_users - scalar @users_exclude_anonymous;
    @users_exclude_anonymous = sort { $a cmp $b } @users_exclude_anonymous;

    my $users = join(',', @users_exclude_anonymous);
    $users .= ",and $num_of_anonymous anonymous users";

    return $c->create_response(
        200,
        [
            'Content-Type'   => 'text/plain; charset=utf8',
            'Content-Length' => length($users)
        ],
        $users
    );
};

builder {
    enable "Plack::Middleware::Static",  path => qr{^/(?:static|vendor)}, root => "$FindBin::Bin";
    __PACKAGE__->to_app();
};

__DATA__

@@ index.tt
<!doctype html>
<html>
<head>
    <met charst="utf-8">
    <title>Module++</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="[% uri_for('/vendor/jquery-2.0.3.min.js') %]"></script>
    <script type="text/javascript" src="[% uri_for('/vendor/underscore-min.js') %]"></script>
    <script type="text/javascript" src="[% uri_for('/static/js/main.js') %]"></script>
    <link rel="stylesheet" href="http://twitter.github.com/bootstrap/1.4.0/bootstrap.min.css">
</head>
<body>
    <div class="container">
        <header><h1>Module++</h1></header>
        <section>
            <form method="post" action="/find" id="ModuleNameForm">
                <input type="text" name="module_name" size="20" required />
                <input type="submit" value="Find" class="btn primary" />
            </form>
            <div id="Loading"></div>
            <ul id="UserList"></ul>
        </section>
        <footer>Powered by <a href="http://amon.64p.org">Amon2::Lite</a></footer>
    </div>
</body>
</html>
