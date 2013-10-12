use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Plack::Builder;
use Amon2::Lite;
use FindBin;
use Furl;
use JSON;

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

{
    package ModulePlusPlus;
    use constant {
        METACPAN_URL => 'http://api.metacpan.org',
        API_FAV      => '/v0/favorite/_search?q=distribution:',
        API_USER     => '/v0/author/_search?q=user:',
        SIZE         => 1000,
    };

    sub fetch_users {
        my $c = shift;
        (my $dist = shift) =~ s/::/-/g;
        my $url_get_fav = METACPAN_URL . API_FAV . $dist . '&fields=user&size=' . SIZE;

        my $furl = Furl->new();
        my $res  = $furl->get($url_get_fav);
        die if !$res->is_success;

        my $json = JSON->new->utf8;
        my $fav  = $json->decode($res->content);

        my @user_names;
        for my $hit (@{ $fav->{hits}{hits} || [] }){
            my $user_hash = $hit->{fields}{user};

            my $user_name;
            my $user_name_arrayref = $c->dbh->selectrow_arrayref(
                "SELECT `user_name` FROM `users` WHERE `user_hash` = ?",
                {},
                ($user_hash),
            );

            if ($user_name_arrayref) {
                $user_name = $user_name_arrayref->[0];
            }
            else {
                my $res = $furl->get(METACPAN_URL . API_USER . $user_hash);
                next if !$res->is_success;

                my $user = $json->decode($res->content);
                $user_name = $user->{hits}{hits}[0]{_source}{pauseid} || '---';

                $c->dbh->insert(
                    'users',
                    +{
                        user_hash => $user_hash,
                        user_name => $user_name,
                    },
                );
            }

            push @user_names, $user_name;
        }
        return \@user_names;
    }
}

get '/' => sub {
    my $c = shift;
    return $c->render('index.tt');
};

post '/find' => sub {
    my $c = shift;

    my $module_name = $c->req->param('module_name');

    my @all_users = @{ModulePlusPlus::fetch_users($c, $module_name)};
    my @users_exclude_anonymous = grep { $_ ne '---' } @all_users;

    my $num_of_anonymous = scalar @all_users - scalar @users_exclude_anonymous;
    @users_exclude_anonymous = sort { $a cmp $b } @users_exclude_anonymous;

    my $users = join(',', @users_exclude_anonymous);
    $users .= ",And $num_of_anonymous anonymous users";

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
