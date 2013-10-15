package App::ModulePlusPlus;
use strict;
use warnings;
use utf8;
use Furl;
use JSON;

use constant {
    METACPAN_URL  => 'http://api.metacpan.org',
    API_MODULE    => '/v0/distribution/',
    API_FAV       => '/v0/favorite/_search?q=distribution:',
    API_USER      => '/v0/author/_search?q=user:',
    SIZE          => 1000,
    NO_ICON_IMAGE => '/static/images/no-icon.png',
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

    my @user_profiles;
    for my $hit (@{ $fav->{hits}{hits} || [] }){
        my $user_hash = $hit->{fields}{user};

        my %user_profile = ();
        my $user_name_arrayref = $c->dbh->selectrow_arrayref(
            "SELECT `user_name`, `user_icon_url` FROM `users` WHERE `user_hash` = ?",
            {},
            ($user_hash),
        );

        if ($user_name_arrayref) {
            $user_profile{'name'}     = $user_name_arrayref->[0];
            $user_profile{'icon_url'} = $user_name_arrayref->[1];
        }
        else {
            my $res = $furl->get(METACPAN_URL . API_USER . $user_hash);
            next if !$res->is_success;

            my $user = $json->decode($res->content);
            $user_profile{'name'}     = $user->{hits}{hits}[0]{_source}{pauseid}      || '---';
            $user_profile{'icon_url'} = $user->{hits}{hits}[0]{_source}{gravatar_url} || NO_ICON_IMAGE;

            $c->dbh->insert(
                'users',
                +{
                    user_hash     => $user_hash,
                    user_name     => $user_profile{'name'},
                    user_icon_url => $user_profile{'icon_url'},
                },
            );
        }

        push @user_profiles, \%user_profile;
    }

    return \@user_profiles, 1;
}

1;
