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

          # 返信メッセージの作成。event.message['text']で送られてきたメッセージを取り出す
          message = {
             type: 'text',
             text: event.message['text']
           }

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

end
