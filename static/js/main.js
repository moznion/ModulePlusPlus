$(function () {
    $('#ModuleNameForm').submit(function () {
        $('#UserList').hide();
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
                error: function () {
                    dfd.reject();
                }
            });
            return dfd.promise();
        };

        var noticeLoading = function () {
            $('#Loading').text($('#Loading').text() + '.');
        };
        var loadingNotifier = setInterval(noticeLoading, 1000);

        prepareUsesList().done(function (res) {
            var users = res.split(',');
            _.each(users, function (user) {
                $('#UserList').append("<li>" + _.escape(user) + "</li>");
            });
            $('#UserList').show();
        }).fail(function () {
            alert("ERROR");
        }).always(function () {
            clearInterval(loadingNotifier);
            $('#Loading').hide();
        });

        return false;
    });
});
