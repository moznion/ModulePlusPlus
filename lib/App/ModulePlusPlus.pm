package App::ModulePlusPlus;
use 5.014001;
use strict;
use warnings;
use utf8;
use Furl;
use JSON;

use constant {
    METACPAN_URL  => 'http://api.metacpan.org',
    API_MODULE    => '/v0/module/',
    API_FAV       => '/v0/favorite/_search?q=distribution:',
    API_USER      => '/v0/author/_search?q=user:',
    SIZE          => 1000,
    NO_ICON_IMAGE => '/static/images/no-icon.png',
};

sub fetch_users {
    my $c = shift;
    (my $module_name = shift) =~ s/::/-/g;

    my $furl = Furl->new();
    my $json = JSON->new->utf8;

    my $dist_arrayref = $c->dbh->selectrow_arrayref(
        "SELECT `dist_name` FROM `modules` WHERE `module_name` = ?",
        {},
        ($module_name),
    );

    my $dist = $dist_arrayref->[0];

    unless (defined($dist)) {
        my $url_get_module_info = METACPAN_URL . API_MODULE . ($module_name =~ s/-/::/gr);
        my $module_info = $furl->get($url_get_module_info);

        if ($module_info->code == 404) {
            return;
        }

        $dist = $json->decode($module_info->content)->{distribution};
        $c->dbh->insert(
            'modules',
            +{
                module_name => $module_name,
                dist_name   => $dist,
            },
        );
    }

    my $url_get_fav = METACPAN_URL . API_FAV . $dist . '&fields=user&size=' . SIZE;

    my $res  = $furl->get($url_get_fav);
    die if !$res->is_success;

    my $fav  = $json->decode($res->content);

    my @user_profiles;
    for my $hit (@{ $fav->{hits}{hits} || [] }){
        my $user_hash = $hit->{fields}{user};

        my %user_profile = ();
        my $user_profile_arrayref = $c->dbh->selectrow_arrayref(
            "SELECT `user_name`, `user_icon_url` FROM `users` WHERE `user_hash` = ?",
            {},
            ($user_hash),
        );

        if ($user_profile_arrayref->[0] && $user_profile_arrayref->[1]) {
            $user_profile{'name'}     = $user_profile_arrayref->[0];
            $user_profile{'icon_url'} = $user_profile_arrayref->[1];
        }
        else {
            my $res = $furl->get(METACPAN_URL . API_USER . $user_hash);
            next if !$res->is_success;

            my $user = $json->decode($res->content);
            $user_profile{'name'}     = $user->{hits}{hits}[0]{_source}{pauseid}      || '---';
            $user_profile{'icon_url'} = $user->{hits}{hits}[0]{_source}{gravatar_url} || NO_ICON_IMAGE;

            $c->dbh->do_i(
                'REPLACE INTO `users`',
                '(`user_hash`, `user_name`, `user_icon_url`)',
                'VALUES',
                '(',
                    \$user_hash, ',', \$user_profile{name}, ',', \$user_profile{icon_url},
                ')',
            );
        }

        push @user_profiles, \%user_profile;
    }

    return \@user_profiles, 1;
}

1;
