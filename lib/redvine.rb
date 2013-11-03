require 'httparty'
require 'hashie'
require 'redvine/version'

class Redvine

  attr_reader :vine_key, :username, :user_id

  @@baseUrl = 'https://api.vineapp.com/'
  @@deviceToken = 'Redvine'
  @@userAgent = 'iphone/1.3.1 (iPhone; iOS 6.1.3; Scale/2.00) (Redvine)'

  def connect(opts={})
    headers = {'User-Agent' => @@userAgent}
    query = get_query(opts)
    url = opts[:isTwitter].eql?(true) ? 'users/authenticate/twitter' : 'users/authenticate'
    response = HTTParty.post(@@baseUrl + url, {body: query, headers: headers})
    @vine_key = response.parsed_response['data']['key']
    @username = response.parsed_response['data']['username']
    @user_id = response.parsed_response['data']['userId']
  end

  def search(tag, opts={})
    raise(ArgumentError, 'You must specify a tag') if !tag
    get_request_data('timelines/tags/' + tag, opts)
  end

  def popular(opts={})
    get_request_data('timelines/popular', opts)
  end

  def promoted(opts={})
    get_request_data('timelines/promoted', opts)
  end

  def timeline(opts={})
    get_request_data('timelines/graph', opts)
  end

  def user_profile(uid)
    raise(ArgumentError, 'You must specify a user id') if !uid
    get_request_data('users/profiles/' + uid, {}, false)
  end

  def user_timeline(uid, opts={})
    raise(ArgumentError, 'You must specify a user id') if !uid
    get_request_data('timelines/users/' + uid, opts)
  end


  private
  def get_query(opts={})
    if opts[:isTwitter].eql?(true)
      {twitterId: opts[:twitterId], twitterOauthSecret: opts[:twitterOauthSecret], twitterOauthToken: opts[:twitterOauthToken], deviceToken: @@deviceToken}
    else
      validate_connect_args(opts)
      return {username: opts[:email], password: opts[:password], deviceToken: @@deviceToken}
    end
  end

  def validate_connect_args(opts={})
    unless opts.has_key?(:email) and opts.has_key?(:email)
      raise(ArgumentError, 'You must specify both :email and :password')
    end
  end

  def session_headers
    {
      'User-Agent' => @@userAgent, 
      'vine-session-id' => @vine_key,
      'Accept' => '*/*', 
      'Accept-Language' => 'en;q=1, fr;q=0.9, de;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5'
    }
  end

  def get_request_data(endpoint, query={}, records=true)
    query.merge!(:size => 20) if query.has_key?(:page) && !query.has_key?(:size)
    args = {:headers => session_headers}
    args.merge!(:query => query) if query != {}
    response = HTTParty.get(@@baseUrl + endpoint, args)
    if response.parsed_response['success'] == false
      response.parsed_response['error'] = true
      return Hashie::Mash.new(response.parsed_response)
    else
      records ? Hashie::Mash.new(response.parsed_response).data.records : Hashie::Mash.new(response.parsed_response).data
    end
  end
end

