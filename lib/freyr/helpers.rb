module Freyr
  def is_root?
    Process.euid == 0
  end

  def has_rvm?
    ENV["rvm_loaded_flag"] == "1"
  end
  class Timeout < StandardError; end
end
