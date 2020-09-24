require 'unisender_dna/client'
module UnisenderDna
  class Sender

    attr_reader :settings

    def initialize(args)
      @settings = { api_key: nil }

      @logger = Rails.logger
      @logger.info "UnisenderDna:INIT"

      args.each do |arg_name, arg_value|
        @settings[arg_name.to_sym] = arg_value
      end

      @client = UnisenderDna::Client.new(@settings[:api_key])
    end

    def deliver!(mail)
      inline_attachments = []
      mail_to    = mail.to

      mail_body = if mail.attachments.present?
        mail.html_part.body.raw_source
      else
        mail.body.raw_source
      end

      @logger.info "--- UnisenderDna: deliver! method ---"
      @logger.info "--- UnisenderDna: mail_to = #{mail_to.inspect} ---"

      return if mail_to.blank?

      send_params =
        {
          "email": mail_to.first,
          "sender_name": @settings[:sender_name],
          "sender_email": mail.from.first,
          "subject": mail.subject,
          "body": mail_body
        }

      @logger.info "--- UnisenderDna: send emails ---"

      result = @client.send_email(send_params)

      body = result[:body]

      @logger.info "--- UnisenderDna: response = #{result.inspect} ---"
      result
    end
  end
end
