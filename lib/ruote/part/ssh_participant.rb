require 'net/ssh'
class SshParticipant < Ruote::Participant

  def initialize(opts)

    @log = Logger.new(nil)
  end

  def consume(wi)

    if wi.params['target'].nil?

      hosts = wi.fields['scoped']
    else

      hosts = wi.fields['scoped'].select{|k,v| v['tags'].include?(wi.params['target']) }
    end

    # TODO should be manipulable &&|| extracted to a config
    user = 'mantor'
    key = wi.params['key'].nil? ? %w(~/.ssh/id_rsa) : wi.params['key']
    port = wi.params['port'].nil? ? 22 : wi.params['port']

    options = { :keys => key, :keys_only => true, :logger => @log, :port => port }
    out = ""
    err = ""
    hosts.each do |h|

      Net::SSH.start(h[1]['name'], user, options) do |ssh|
        ssh.open_channel do |channel|
          channel.exec("fetch") do |ch, success|
            #abort "could not execute command" unless success # TODO trigger cancel or retry

            ch.on_data do |ch, data|
              out << data
            end

            ch.on_extended_data do |ch, type, data|
              err << data
            end

            ch.on_close do |ch|
              puts "channel is closing!"
            end
          end
        end

        ssh.loop
      end
    end

    wi.fields['stdout'] = out
    wi.fields['stderr'] = err

    reply_to_engine(wi)
  end

  def on_cancel

   # TODO
  end
end