require 'format_logs/version'

module FormatLogs
  
  def self.included(base)
    puts "Adding formatting to #{base.name}"
    base.send :extend, ClassMethods
    
    base.send :include, InstanceMethods
    base.alias_method_chain :add, :formatting # if base.respond_to? :add
  end
  
  module ClassMethods
    
    def settings
      @settings ||= default_settings
    end
    
    def settings=(new_settings)
      @settings = default_settings + new_settings
      flush_attributes!
    end
    
    def flush_cached_settings!
      [@time_format, @show_time, @show_pid, @show_host].each {|a| a = nil}
    end
    
    def default_settings
      {
        :time_format => '%Y-%m-%d %H:%M:%S %z',
        :show_pid => true,
        :show_host => true,
        :show_time => true
      }
    end
    
    def time_format
      @time_format ||= settings[:time_format]
    end
    
    def show_time?
      @show_time ||= settings[:show_time]
    end
    
    def use_color?
      @use_color ||= (Rails.configuration.colorize_logging != false)
    end
    
    def show_pid?
      @show_pid ||= settings[:show_pid]
    end
    
    def show_host?
      @show_host ||= settings[:show_host]
    end
    
    def timestamp
      "#{Time.now.utc.strftime(time_format)} - " if show_time?
    end
    
    def pid
      "#{$$} - " if show_pid?
    end
    
    def hostname
      @hostname ||= "#{`hostname -s`.strip rescue ''} - " if show_host?
    end
    
    def to_color(severity)
      return case severity
        when ActiveSupport::BufferedLogger::INFO  then info_s
        when ActiveSupport::BufferedLogger::WARN  then warn_s
        when ActiveSupport::BufferedLogger::ERROR then error_s
        when ActiveSupport::BufferedLogger::FATAL then fatal_s
        when ActiveSupport::BufferedLogger::DEBUG then debug_s
      else unknown_s
      end
    end
    
    def debug_s
      "DEBUG "
    end
    
    def unknown_S
      "UNKNOWN"
    end
    
    def info_s
      @info_s ||= color("INFO  ", '32m')
    end
    
    def warn_s
      @warn_s ||= color("WARN  ", '33m')
    end
    
    def error_s
      @error_s ||= color("ERROR ", '31m')
    end
    
    def fatal_s
      @fatal_s ||= color("FATAL ", '1;30;41m')
    end
    
    def color(s, color)
      use_color? ? "\033[#{color}#{s}\033[0m" : s
    end
    
  end
  
  module InstanceMethods
    
    def add_with_formatting(severity, message = nil, progname = nill, &block)
      return if @level > severity
      message = format(severity, (message || (block && block.call) || progname).to_s)
      add_without_formatting(severity, message, progname)
    end
    
    def format(severity, message)
      "#{self.class.pid}#{self.class.hostname}#{self.class.timestamp}#{self.class.to_color(severity)} - #{message}"
    end
   
  end
  

end

ActiveSupport::BufferedLogger.send :include, FormattedLogger