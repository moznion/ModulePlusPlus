package App::ModulePlusPlus;
use strict;
use warnings;
use utf8;
use Furl;
use JSON;

use constant {
    METACPAN_URL => 'http://api.metacpan.org',
    API_MODULE   => '/v0/distribution/',
    API_FAV      => '/v0/favorite/_search?q=distribution:',
    API_USER     => '/v0/author/_search?q=user:',
    SIZE         => 1000,
};

sub fetch_users {
    my $c = shift;
    (my $dist = shift) =~ s/::/-/g;

    my $furl = Furl->new();

    my $dist_arrayref = $c->dbh->selectrow_arrayref(
        "SELECT `id` FROM `distributions` WHERE `name` = ?",
        {},
        ($dist),
    );

    unless (defined($dist_arrayref)) {
        my $url_get_module_exist = METACPAN_URL . API_MODULE . $dist;
        if ($furl->get($url_get_module_exist)->code == 404) {
            return;
        }

        $c->dbh->insert(
            'distributions',
            +{
                name => $dist,
            },
        );
    }

    my $url_get_fav = METACPAN_URL . API_FAV . $dist . '&fields=user&size=' . SIZE;

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
    return \@user_names, 1;
}

1;
