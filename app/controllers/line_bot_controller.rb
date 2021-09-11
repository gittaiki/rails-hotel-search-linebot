class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]
  
  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      return head :bad_request
    end

    # eventsの要素を配列で取得
    events = client.parse_events_from(body)

    # events変数をeachメソッドを用いてループさせ、各要素をevent変数として扱う
    events.each do |event|

      # eventがLine::Bot::Event::Messageクラスか確認
      case event
      when Line::Bot::Event::Message

        # Line::Bot::Event::MessageTypeがtextであるか確認
        case event.type
        when Line::Bot::Event::MessageType::Text

          # search_and_create_message(event.message['text'])

          # 返信メッセージの作成。event.message['text']で送られてきたメッセージを取り出す
          # message = {
          #    type: 'text',
          #    text: event.message['text']
          #  }

          # ユーザーから送信されたメッセージであるevent.message['text']を引数に指定
          message = search_and_create_message(event.message['text'])

           # 返信に応答トークンが必要のため設定。そして返信メッセージを渡している。
           client.reply_message(event['replyToken'], message)
        end
      end
    end
    # 正常を示すステータスコードである200を返す
    head :ok
  end

  private

  # Line::Bot::Clientクラスをインスタンス化し、メッセージの解析や返信などの機能を使えるようにする
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  # 引数としてLINEアプリから送信されたメッセージkeywordを受け取る
  def search_and_create_message(keyword)

    # HTTPClientクラスをインスタンス化し、http_client変数に代入
    http_client = HTTPClient.new

    # 楽天トラベルキーワード検索APIのリクエストURLをurl変数に代入
    url = 'https://app.rakuten.co.jp/services/api/Travel/KeywordHotelSearch/20170426'
    
    # パラメーターを定義したハッシュをquery変数に代入
    query = {
      'keyword' => keyword,
      'applicationId' => ENV['RAKUTEN_APPID'],
      'hits' => 5,
      'responseType' => 'small',
      'formatVersion' => 2
    }

    # getメソッドの第一引数にはリクエストURLを渡し、第二引数にはパラメーターをハッシュで渡し、結果(レスポンス)をresponse変数に代入
    response = http_client.get(url, query)

    # JSON.parseメソッドを使って、検索結果が格納されたレスポンスボディを文字列からハッシュに変換
    response = JSON.parse(response.body)

    # p response['pagingInfo']

    if response.key?('error')
      text = "この検索条件に該当する宿泊施設が見つかりませんでした。\n条件を変えて再検索してください。"
    else

      # <<演算子はStringクラスの値でしか使うことができないため、Stringクラスの変数として宣言
      text = ''
      response['hotels'].each do |hotel|

        # 作成した文字列はtextへ代入しますが、<<演算子を利用することで、すでに格納されている文字列に連結
        text <<
          hotel[0]['hotelBasicInfo']['hotelName'] + "\n" +
          hotel[0]['hotelBasicInfo']['hotelInformationUrl'] + "\n" +
          "\n"
      end
    end

    # textキーの値にホテル情報を連結させたテキストであるtext変数を指定し、message変数に代入
    message = {
      type: 'text',
      text: text
    }
  end

end
