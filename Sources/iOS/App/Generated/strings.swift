// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
internal enum L10n {
  internal enum Localizable {
    /// キャンセル
    internal static let cancel = L10n.tr("Localizable", "cancel")
    /// 接続
    internal static let connect = L10n.tr("Localizable", "connect")
    /// 接続中
    internal static let connected = L10n.tr("Localizable", "connected")
    /// 現在のアカウント: @%@
    internal static func currentAccount(_ p1: String) -> String {
      return L10n.tr("Localizable", "currentAccount", p1)
    }
    /// 切断
    internal static let disconnect = L10n.tr("Localizable", "disconnect")
    /// 取得失敗
    internal static let fetchFailed = L10n.tr("Localizable", "fetchFailed")
    /// ヘルプ / Feedback
    internal static let helpAndFeedback = L10n.tr("Localizable", "helpAndFeedback")
    /// ホームタイムライン
    internal static let homeTimeline = L10n.tr("Localizable", "homeTimeline")
    /// リスト
    internal static let lists = L10n.tr("Localizable", "lists")
    /// ローカルタイムライン
    internal static let localTimeline = L10n.tr("Localizable", "localTimeline")
    /// 自分のプロフィール
    internal static let myProfile = L10n.tr("Localizable", "myProfile")
    /// 接続していません
    internal static let notConnected = L10n.tr("Localizable", "notConnected")
    /// ここまで
    internal static let nothingMore = L10n.tr("Localizable", "nothingMore")
    /// 通知
    internal static let notifications = L10n.tr("Localizable", "notifications")
    /// その他
    internal static let other = L10n.tr("Localizable", "other")
    /// 投稿
    internal static let post = L10n.tr("Localizable", "post")
    /// もっと
    internal static let readmore = L10n.tr("Localizable", "readmore")
    /// 再取得
    internal static let refetch = L10n.tr("Localizable", "refetch")
    /// 設定
    internal static let settings = L10n.tr("Localizable", "settings")
    /// Streaming
    internal static let streaming = L10n.tr("Localizable", "streaming")
    /// 状態: %@
    internal static func streamingStatus(_ p1: String) -> String {
      return L10n.tr("Localizable", "streamingStatus", p1)
    }
    /// アカウントを変更
    internal static let switchActiveAccount = L10n.tr("Localizable", "switchActiveAccount")
    internal enum Error {
      /// インスタンスを入力してください。
      internal static let pleaseInputInstance = L10n.tr("Localizable", "error.pleaseInputInstance")
      /// この機能はMastodonインスタンスのバージョンが%@以上でないと利用できません。\n(iMastを起動中にインスタンスがアップデートされた場合は、アプリを再起動すると利用できるようになります)\nMastodonインスタンスのアップデート予定については、各インスタンスの管理者にお尋ねください。
      internal static func requiredNewerMastodon(_ p1: String) -> String {
        return L10n.tr("Localizable", "error.requiredNewerMastodon", p1)
      }
      /// この機能を利用するためには iOS %.1f 以上が必要です。
      internal static func requiredNewerOS(_ p1: Float) -> String {
        return L10n.tr("Localizable", "error.requiredNewerOS", p1)
      }
      /// エラー
      internal static let title = L10n.tr("Localizable", "error.title")
    }
    internal enum HomeTimeline {
      /// ホー�
      internal static let short = L10n.tr("Localizable", "homeTimeline.short")
    }
    internal enum LocalTimeline {
      /// LTL
      internal static let short = L10n.tr("Localizable", "localTimeline.short")
    }
  }
  internal enum Login {
    /// ログイン
    internal static let loginButton = L10n.tr("Login", "loginButton")
    /// Mastodonのインスタンスを入力してください
    internal static let pleaseInputMastodonInstance = L10n.tr("Login", "pleaseInputMastodonInstance")
    /// ログイン
    internal static let title = L10n.tr("Login", "title")
    internal enum Authorize {
      /// 認証
      internal static let title = L10n.tr("Login", "authorize.title")
      internal enum Method {
        /// メールアドレスとパスワードでログイン
        internal static let mailAndPassword = L10n.tr("Login", "authorize.method.mailAndPassword")
        /// Safariでログイン (推奨)
        internal static let safari = L10n.tr("Login", "authorize.method.safari")
      }
      internal enum Tos {
        /// ログインすることで、以下のルールやプライバシーポリシーなどに同意したことになります。
        internal static let header = L10n.tr("Login", "authorize.tos.header")
        /// このサーバーのルール
        internal static let rules = L10n.tr("Login", "authorize.tos.rules")
        /// このサーバーの利用規約
        internal static let termsOfService = L10n.tr("Login", "authorize.tos.termsOfService")
      }
    }
    internal enum PasswordLogin {
      /// メールアドレス
      internal static let mailAddress = L10n.tr("Login", "passwordLogin.mailAddress")
      /// パスワード
      internal static let password = L10n.tr("Login", "passwordLogin.password")
    }
    internal enum ProgressDialog {
      /// サーバーの情報を取得中…
      internal static let fetchingServerInfo = L10n.tr("Login", "progressDialog.fetchingServerInfo")
      /// 認証してください
      internal static let pleaseAuthorize = L10n.tr("Login", "progressDialog.pleaseAuthorize")
      /// アプリをサーバーに登録中…
      internal static let registeringApplication = L10n.tr("Login", "progressDialog.registeringApplication")
      /// ログイン中
      internal static let title = L10n.tr("Login", "progressDialog.title")
    }
    internal enum Welcome {
      /// ようこそ、\n%@\nさん。
      internal static func message(_ p1: String) -> String {
        return L10n.tr("Login", "welcome.message", p1)
      }
    }
  }
  internal enum Notification {
    internal enum Types {
      /// @%@さんにブーストされました
      internal static func boost(_ p1: String) -> String {
        return L10n.tr("Notification", "types.boost", p1)
      }
      /// @%@さんにふぁぼられました
      internal static func favourite(_ p1: String) -> String {
        return L10n.tr("Notification", "types.favourite", p1)
      }
      /// @%@さんにフォローされました
      internal static func follow(_ p1: String) -> String {
        return L10n.tr("Notification", "types.follow", p1)
      }
      /// @%@さんからのメンション
      internal static func mention(_ p1: String) -> String {
        return L10n.tr("Notification", "types.mention", p1)
      }
      /// 不明な通知: %@
      internal static func unknown(_ p1: String) -> String {
        return L10n.tr("Notification", "types.unknown", p1)
      }
      internal enum Poll {
        /// あなたが参加した投票が終了しました
        internal static let notowner = L10n.tr("Notification", "types.poll.notowner")
        /// あなたが作成した投票が終了しました
        internal static let owner = L10n.tr("Notification", "types.poll.owner")
      }
    }
  }
  internal enum Search {
    /// 検索
    internal static let title = L10n.tr("Search", "title")
    internal enum Sections {
      internal enum Accounts {
        /// アカウント
        internal static let title = L10n.tr("Search", "sections.accounts.title")
      }
      internal enum Hashtags {
        /// ハッシュタグ
        internal static let title = L10n.tr("Search", "sections.hashtags.title")
      }
      internal enum Posts {
        /// 投稿
        internal static let title = L10n.tr("Search", "sections.posts.title")
      }
      internal enum TrendTags {
        /// トレンドタグ (更新: %@)
        internal static func title(_ p1: String) -> String {
          return L10n.tr("Search", "sections.trendTags.title", p1)
        }
      }
    }
  }
  internal enum UserProfile {
    /// このユーザーは外部インスタンスに所属しているため、一部の数値が正確でない場合があります。
    internal static let federatedUserWarning = L10n.tr("UserProfile", "federatedUserWarning")
    /// プロフィール
    internal static let title = L10n.tr("UserProfile", "title")
    internal enum Actions {
      /// ブロック
      internal static let block = L10n.tr("UserProfile", "actions.block")
      /// キャンセル
      internal static let cancel = L10n.tr("UserProfile", "actions.cancel")
      /// フォロー
      internal static let follow = L10n.tr("UserProfile", "actions.follow")
      /// フォローリクエストを撤回
      internal static let followRequestCancel = L10n.tr("UserProfile", "actions.followRequestCancel")
      /// フォローリクエスト一覧
      internal static let followRequestsList = L10n.tr("UserProfile", "actions.followRequestsList")
      /// ミュート
      internal static let mute = L10n.tr("UserProfile", "actions.mute")
      /// 名刺
      internal static let profileCard = L10n.tr("UserProfile", "actions.profileCard")
      /// 共有
      internal static let share = L10n.tr("UserProfile", "actions.share")
      /// アクション
      internal static let title = L10n.tr("UserProfile", "actions.title")
      /// ブロック解除
      internal static let unblock = L10n.tr("UserProfile", "actions.unblock")
      /// フォロー解除
      internal static let unfollow = L10n.tr("UserProfile", "actions.unfollow")
      /// ミュート解除
      internal static let unmute = L10n.tr("UserProfile", "actions.unmute")
    }
    internal enum Cells {
      internal enum CreatedAt {
        /// 登録日
        internal static let title = L10n.tr("UserProfile", "cells.createdAt.title")
      }
      internal enum Followers {
        /// フォロワー
        internal static let title = L10n.tr("UserProfile", "cells.followers.title")
      }
      internal enum Following {
        /// フォロー
        internal static let title = L10n.tr("UserProfile", "cells.following.title")
      }
      internal enum Toots {
        /// トゥート
        internal static let title = L10n.tr("UserProfile", "cells.toots.title")
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // swiftlint:disable:next nslocalizedstring_key
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
