module Freyr
  class ProcessInfo
    attr_accessor :user, :pid, :cpu, :mem, :vsz, :rss, :tt, :stat, :started, :time, :cmd
  end
end