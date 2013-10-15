$(function () {
    $('#ModuleNameForm').submit(function () {
        $('#UserList').hide();
        $('#MoreInfo').empty();
        $('.user').remove();
        $('#Loading').text('Now Loading').show();

        var self = this;

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
            _.each(users, function (user) {
                $('#UserList').append("<li class='user'>" + _.escape(user) + "</li>");
            });
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
            if (err.status === 404) {
                var paragraph = $("#MoreInfo");
                paragraph = $("<p />").attr("id", "MoreInfo");
                $("#UserList").after(paragraph);
                paragraph.text(err.responseText);
            }
        }).always(function () {
            clearInterval(loadingNotifier);
            $('#Loading').hide();
        });

        return false;
    });
});
