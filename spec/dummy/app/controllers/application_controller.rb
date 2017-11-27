class ApplicationController < ActionController::Base
  def not_modified
    render plain: '', status: 304
  end

  def gone
    render plain: '', status: 410
  end

  def internal_server_error
    render plain: '', status: 500
  end
end
