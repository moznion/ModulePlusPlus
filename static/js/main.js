var mpp = mpp || {};

mpp.searchModule = function(self){
    var author_url = 'https://metacpan.org/author/';

    $('#UserList').hide();
    $('#MoreInfo').empty();
    $('.user').remove();
    $('#Loading').text('Now Loading').show();

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
            var name = users[i];
            var $name_as_link = $('<a/>').attr({'href': author_url + name, 'target': '_blank'});
            $name_as_link.append(name);

            var icon_url = iconSizeModifyFilter(users[i + 1], 16);
            var $icon = $('<img/>').attr({'src': icon_url, 'alt': 'icon'});
            var $icon_as_link = $('<a/>').attr({'href': author_url + name, 'target': '_blank'});
            $icon_as_link.append($icon)

            var $li = $('<li/>').addClass('user');
            $li.append($icon_as_link);
            $li.append($name_as_link);

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

};

$(function () {
    var hash = location.hash.replace(/^#/, "");

    if(hash.length > 0){
        $("#ModuleNameForm").find("input").val(hash);
        mpp.searchModule($("#ModuleNameForm"));
    }

    $('#ModuleNameForm').submit(function () {
        location.hash = $(this).find("input").val();
        mpp.searchModule(this);

        return false;
    });
});
