# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'net/pop'

class Channel::Driver::Pop3 < Channel::EmailParser

=begin

fetch emails from Pop3 account

  instance = Channel::Driver::Imap.new
  result = instance.fetch(params[:inbound][:options], channel, 'verify', subject_looking_for)

returns

  {
    result: 'ok',
    fetched: 123,
    notice: 'e. g. message about to big emails in mailbox',
  }

check if connect to Pop3 account is possible, return count of mails in mailbox

  instance = Channel::Driver::Imap.new
  result = instance.fetch(params[:inbound][:options], channel, 'check')

returns

  {
    result: 'ok',
    content_messages: 123,
  }

verify Pop3 account, check if search email is in there

  instance = Channel::Driver::Imap.new
  result = instance.fetch(params[:inbound][:options], channel, 'verify', subject_looking_for)

returns

  {
    result: 'ok', # 'verify not ok'
  }

=end

  def fetch (options, channel, check_type = '', verify_string = '')
    ssl  = true
    port = 995
    if options.key?(:ssl) && options[:ssl].to_s == 'false'
      ssl  = false
      port = 110
    end

    Rails.logger.info "fetching pop3 (#{options[:host]}/#{options[:user]} port=#{port},ssl=#{ssl})"

    @pop = Net::POP3.new( options[:host], port )
    #@pop.set_debug_output $stderr

    # on check, reduce open_timeout to have faster probing
    @pop.open_timeout = 8
    @pop.read_timeout = 12
    if check_type == 'check'
      @pop.open_timeout = 4
      @pop.read_timeout = 6
    end

    if ssl
      @pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE)
    end
    @pop.start(options[:user], options[:password])

    mails = @pop.mails

    if check_type == 'check'
      Rails.logger.info 'check only mode, fetch no emails'
      content_max_check = 2
      content_messages  = 0

      # check messages
      mails.each do |m|
        mail = m.pop
        next if !mail

        # check how many content messages we have, for notice used
        if mail !~ /x-zammad-ignore/i
          content_messages += 1
          break if content_max_check < content_messages
        end
      end
      if content_messages >= content_messages
        content_messages = mails.count
      end
      disconnect
      return {
        result: 'ok',
        content_messages: content_messages,
      }
    end

    # reverse message order to increase performance
    if check_type == 'verify'
      Rails.logger.info 'verify mode, fetch no emails'
      mails.reverse!

      # check for verify message
      mails.each do |m|
        mail = m.pop
        next if !mail

        # check if verify message exists
        if mail =~ /#{verify_string}/
          Rails.logger.info " - verify email #{verify_string} found"
          m.delete
          disconnect
          return {
            result: 'ok',
          }
        end
      end

      return {
        result: 'verify not ok',
      }
    end

    # fetch regular messages
    count_all     = mails.size
    count         = 0
    count_fetched = 0
    notice        = ''
    mails.each do |m|
      count += 1
      Rails.logger.info " - message #{count}/#{count_all}"

      mail = m.pop

      # ignore to big messages
      max_message_size = Setting.get('postmaster_max_size')
      real_message_size = mail.size.to_f / 1024 / 1024
      if real_message_size > max_message_size
        info = "  - ignore message #{count}/#{count_all} - because message is to big (is:#{real_message_size}/max:#{max_message_size} in MB)"
        Rails.logger.info info
        notice += "#{info}\n"
        next
      end

      # delete email from server after article was created
      if process(channel, m.pop)
        m.delete
        count_fetched += 1
      end
    end
    disconnect
    if count == 0
      Rails.logger.info ' - no message'
    end
    Rails.logger.info 'done'
    {
      result: 'ok',
      fetched: count_fetched,
      notice: notice,
    }
  end

  def disconnect
    return if !@pop
    @pop.finish
  end

end
