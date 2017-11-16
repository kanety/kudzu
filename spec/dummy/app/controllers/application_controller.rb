class ApplicationController < ActionController::Base
  def not_modified
    render plain: '', status: 304
  end

  def gone
    render plain: '', status: 410
  end
end
