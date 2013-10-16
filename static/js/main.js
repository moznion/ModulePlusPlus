$(function () {
    var author_url = 'https://metacpan.org/author/';

    $('#ModuleNameForm').submit(function () {
        $('#UserList').hide();
        $('#MoreInfo').empty();
        $('.user').remove();
        $('#Loading').text('Now Loading').show();

        var self = this;

        var iconSizeModifyFilter = function(url, size) {
            return url.replace(/\b(s|size)=(\d+)\b/, '$1=' + size);
        };

        var prepareUsesList = function () {
            var dfd = $.Deferred();
            $.ajax({
                url:  '/find',
                type: 'post',
                data: $(self).serialize(),
                success: function (res) {
                    dfd.resolve(res);
                },
                error: function (err) {
                    dfd.reject(err);
                }
            });
            return dfd.promise();
        };

        var noticeLoading = function () {
            $('#Loading').text($('#Loading').text() + '.');
        };
        var loadingNotifier = setInterval(noticeLoading, 1000);

        prepareUsesList().done(function (res) {
            var splitres = res.split(',');
            var users = splitres.slice(0, splitres.length - 1);
            for (var i = 0; i < users.length; i += 2) {
                var name    = users[i];
                var $link   = $('<a/>').attr({'href': author_url + name, 'target': '_blank'});
                $link.append(name);

                var iconURL = iconSizeModifyFilter(users[i + 1], 32);
                var $li = $('<li/>').addClass('user');
                var $icon = $('<img/>').attr({'src': iconURL, 'alt': 'icon'});

                $li.append($icon);
                $li.append($link);

                $('#UserList').append($li);
            }

            if (users.length > 0) {
                $('#UserList').show();
            }

            var anonymouses = splitres[splitres.length - 1];
            var paragraph = $("#MoreInfo");
            if (paragraph.length == 0) {
                paragraph = $("<p />").attr("id", "MoreInfo");
                $("#UserList").after(paragraph);
            }
            paragraph.text(anonymouses);

        }).fail(function (err) {
            var paragraph = $("#MoreInfo");
            paragraph = $("<p />").attr("id", "MoreInfo");
            $("#UserList").after(paragraph);
            if (err.status === 404) {
                paragraph.text(err.responseText);
            } else {
                paragraph.text('Something wrong...');
            }
        }).always(function () {
            clearInterval(loadingNotifier);
            $('#Loading').hide();
        });

        return false;
    });
});
