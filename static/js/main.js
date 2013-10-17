/**
 * Module++モジュール
 * @class mpp
 */
var mpp = mpp || {};

/**
 * Authorの画像等抽出用のベースURL
 * @property author_url
 */
mpp.author_url = 'https://metacpan.org/author/';

/**
 * 読み込み時、Now Loading の末尾に出る . の追加処理用の interval ID
 * @property loadingNotifier
 */
mpp.loadingNotifier = -1;

/**
 * 検索開始時、画面表示をリセットする
 * @method resetView
 */
mpp.resetView = function(){
    $('#UserList').hide();
    $('#MoreInfo').empty();
    $('.user').remove();
    $('#Loading').text('Now Loading').show();
};

/**
 * url中に記述されている画像サイズの指定を、sizeの値のものに変更する
 *
 * @method iconSizeModifyFilter
 * @param {string} url 画像URL
 * @param {number} size 画像サイズ
 * @return {string} 画像サイズ指定部分が変更されたicon画像URL
 */
mpp.iconSizeModifyFilter = function(url, size) {
    return url.replace(/\b(s|size)=(\d+)\b/, '$1=' + size);
};

/**
 * ローディング時、"nowLoading"の文字の末尾に.を追加する
 * @method noticeLoading
 */
mpp.noticeLoading = function () {
    $('#Loading').text($('#Loading').text() + '.');
};

/**
 * ajaxで指定のモジュールに＋＋してるユーザーを拾ってくる
 * $.Deferred対応
 * @mathod prepareUserList
 * @param {HTMLElement|jQuery object} form formタグのDOM
 * @return {Promise} Deferredのpromise
 */
mpp.prepareUsesList = function (form) {
    var dfd = $.Deferred();
    $.ajax({
        url:  '/find',
        type: 'post',
        data: $(form).serialize(),
        success: function (res) {
            dfd.resolve(res);
        },
        error: function (err) {
            dfd.reject(err);
        }
    });
    return dfd.promise();
};

/**
 * 取得したユーザーリストを元に、HTMLを生成して表示する
 * prepareUserListが成功した際に呼ばれるハンドラ
 * @method done
 * @param {csv} res CSV形式のユーザー名リスト
 */
mpp.done = function(res){
    var splitres = res.split(',');
    var users = splitres.slice(0, splitres.length - 1);
    for (var i = 0; i < users.length; i += 2) {
        var name = users[i];
        var $name_as_link = $('<a/>').attr({'href': mpp.author_url + name, 'target': '_blank'});
        $name_as_link.append(name);

        var icon_url = mpp.iconSizeModifyFilter(users[i + 1], 16);
        var $icon = $('<img/>').attr({'src': icon_url, 'alt': 'icon'});
        var $icon_as_link = $('<a/>').attr({'href': mpp.author_url + name, 'target': '_blank'});
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
    paragraph.text(anonymouses);

};

/**
 * ajaxが失敗した時（モジュール名がなくて404が帰ってきた時）に
 * その旨を表示する
 * @method fail
 * @param {Error} エラーオブジェクト
 */
mpp.fail = function(err){
    var paragraph = $("#MoreInfo");
    if (err.status === 404) {
        paragraph.text(err.responseText);
    } else {
        paragraph.text('Something wrong...');
    }
};

/**
 * ajaxの後処理として、NowLoadingの.増加処理を止め、文字を消してる
 * @method always
 */
mpp.always = function(){
    clearInterval(mpp.loadingNotifier);
    mpp.loadingNotifier = -1;
    $('#Loading').hide();
};

/**
 * モジュール名から＋＋してるユーザー名を取得するための一般処理
 * @method searchModule
 * @param {HTMLElement|jQuery object} フォーム
 */
mpp.searchModule = function(form){
    mpp.resetView();
    mpp.loadingNotifier = setInterval(mpp.noticeLoading, 1000);

    mpp.prepareUsesList(form).done(mpp.done).fail(mpp.fail).always(mpp.always);
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
