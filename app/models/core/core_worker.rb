class CoreWorker < CoreModel
  include SidekiqUtils
  include Trackable

  def i_am_alone?(domain=nil)
    return true if Rails.env.test?
    if domain
      workers_for_class("#{self.class}").select { |w| worker_domain(w) == domain }.count < 2
    else
      workers_for_class("#{self.class}").count < 2
    end
  end
end
