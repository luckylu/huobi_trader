class SignatureService
  def self.execute(method, path, params, domain = 'api.huobi.pro')
    new(method, path, params, domain).perform
  end

  def initialize(method, path, params, domain)
    @method = method
    @path = path
    @params = params
    @domain = domain
  end

  def perform
    URI.encode_www_form(sort.push([:Signature, sign]))
  end

  private

  def encode_www_form
    URI.encode_www_form(sort)
  end

  def sort
    @params ||= {}
    @params.merge!(default_params).sort
  end

  def default_params
    {
      AccessKeyId: Rails.application.secrets.huobi[:access_key],
      SignatureMethod: 'HmacSHA256',
      SignatureVersion: 2,
      Timestamp: Time.now.utc.iso8601.chop
    }
  end

  def sign
    raw_data = <<~SIGN
      #{@method}
      #{@domain}
      #{@path}
      #{encode_www_form}
    SIGN
    secret_key = Rails.application.secrets.huobi[:secret_key]
    Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), secret_key, raw_data.chomp)).strip
  end
end
