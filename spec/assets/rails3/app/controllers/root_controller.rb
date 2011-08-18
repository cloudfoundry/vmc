class RootController < ApplicationController
  def index
  end

  def make_widget
    widget = Widget.new :name => params[:name]
    if widget.save
      render :text => "Saved #{widget.name}"
    else
      render :text => "FAIL", :status => 400
    end
  end
end
