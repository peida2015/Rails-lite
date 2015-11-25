require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'

require 'byebug'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, route_params = {})
    @req, @res, @params = req, res, route_params
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response ? true : false
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "Can't double render" if already_built_response?
    self.res['Location'] = url
    @already_built_response = true
    self.res.status = 302
    session.store_session(res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise "Can't double render" if already_built_response?
    @already_built_response = true
    self.res['Content-Type'] = content_type
    self.res.write(content)
    session.store_session(res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller_class_name = self.class.to_s
    controller_name = controller_class_name.underscore
    filename = "./views/#{controller_name}/#{template_name}.html.erb"
    file_content = File.read(filename)
    content = ERB.new(file_content).result(binding)
    render_content(content, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
  end
end
