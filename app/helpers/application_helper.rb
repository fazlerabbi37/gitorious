# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  
  def default_css_tag_sizes
    %w(tag_size_1 tag_size_2 tag_size_3 tag_size_4)
  end
  
  def linked_tag_list_as_sentence(tags)
    tags.map do |tag|
      link_to(h(tag.name), search_path(:q => "category:#{h(tag.name)}"))
    end.to_sentence
  end
  
  def build_notice_for(object)
    out =  %Q{<div class="being_constructed">}
    out << %Q{  <p>This #{object.class.name.humanize.downcase} is being created,<br />}
    out << %Q{  it will be ready pretty soon&hellip;</p>}
    out << %Q{</div>}
    out
  end
  
  def render_if_ready(object, &blk)
    if object.respond_to?(:ready?) && object.ready?
      yield
    else
      concat(build_notice_for(object), blk.binding)
    end
  end  
  
  def selected_if_current_page(url_options, slack = false)
    if slack
      if controller.request.request_uri.index(CGI.escapeHTML(url_for(url_options))) == 0
        "selected"
      end
    else
      "selected" if current_page?(url_options)
    end
  end
  
  def link_to_with_selected(name, options = {}, html_options = nil)
    html_options = current_page?(options) ? {:class => "selected"} : nil
    link_to(name, options = {}, html_options)
  end
  
  def syntax_themes_css
    out = []
    if @load_syntax_themes
      # %w[ active4d all_hallows_eve amy blackboard brilliance_black brilliance_dull 
      #     cobalt dawn eiffel espresso_libre idle iplastic lazy mac_classic 
      #     magicwb_amiga pastels_on_dark slush_poppies spacecadet sunburst 
      #     twilight zenburnesque 
      # ].each do |syntax|
      #   out << stylesheet_link_tag("syntax_themes/#{syntax}")
      # end
      return stylesheet_link_tag("syntax_themes/idle")
    end
    out.join("\n")
  end
  
  def base_url(full_url)
    URI.parse(full_url).host
  end
  
  def gravatar_url_for(email, options = {})
    "http://www.gravatar.com/avatar.php?gravatar_id=" << 
    Digest::MD5.hexdigest(email) << 
    "&amp;default=" <<
    u("http://#{request.host}:#{request.port}/images/default_face.gif") <<
    options.map { |k,v| "&amp;#{k}=#{v}" }.join
  end
  
  def gravatar(email, options = {})
    size = options[:size]
    image_options = { :alt => "avatar" }
    if size
      image_options.merge!(:width => size, :height => size)
    end
    image_tag(gravatar_url_for(email, options), image_options)
  end
  
  def gravatar_frame(email, options = {})
    extra_css_class = options[:style] ? " gravatar_#{options[:style]}" : ""
    %{<div class="gravatar#{extra_css_class}">#{gravatar(email, options)}</div>}
  end
  
  def flashes
    flash.map { |type, content| content_tag(:div, content_tag(:p, content), :class => "flash_message #{type}")}
  end
  
  def commit_graph_tag(repository, ref = "master")
    filename = "#{repository.project.slug}_#{repository.name}_#{h(ref)}_commit_count.png"
    if File.exist?(File.join(Gitorious::Graphs::Builder.graph_dir, filename))
      image_tag("graphs/#{filename}")
    end
  end
  
  def commit_graph_by_author_tag(repository, ref = "master")    
    filename = "#{repository.project.slug}_#{repository.name}_#{h(ref)}_commit_count_by_author.png"
    if File.exist?(File.join(Gitorious::Graphs::Builder.graph_dir, filename))
      image_tag("graphs/#{filename}")
    end
  end
  
  def action_and_body_for_event(event)
    target = event.target
    action = ""
    body = ""
    case event.action
      when Action::CREATE_PROJECT
        action = "<b>created project</b> #{link_to h(target.title), project_path(target)}"
        body = truncate(target.stripped_description, 100)
      when Action::DELETE_PROJECT
        action = "<b>deleted project</b> #{h(event.data)}"
      when Action::UPDATE_PROJECT
        action = "<b>updated project</b> #{link_to h(target.title), project_path(target)}"
      when Action::CLONE_REPOSITORY
        original_repo = Repository.find_by_id(event.data.to_i)
        next if original_repo.nil?
        
        project = target.project
        
        action = "<b>forked</b> #{link_to h(project.title), project_path(project)}/#{link_to h(original_repo.name), project_repository_url(project, original_repo)} in #{link_to h(target.name), project_repository_url(project, target)}"
      when Action::DELETE_REPOSITORY
        action = "<b>deleted repository</b> #{link_to h(target.title), project_path(target)}/#{event.data}"
      when Action::COMMIT
        project = target.project
        action = "<b>commited to</b> #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
        body = "#{link_to event.data, project_repository_commit_path(project, target, event.data)}<br/>#{event.body}"
      when Action::CREATE_BRANCH
        project = target.project
        if event.data == "master"
          action = "<b>started development</b> of #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
          body = event.body
        else
          action = "<b>created branch</b> #{link_to h(event.data), project_repository_tree_path(project, target, event.data)} on #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
        end
      when Action::DELETE_BRANCH
        project = target.project
        action = "<b>deleted branch</b> #{event.data} on #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
      when Action::CREATE_TAG
        project = target.project
        action = "<b>tagged</b> #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
        body = "#{link_to event.data, project_repository_commit_path(project, target, event.data)}<br/>#{event.body}"
      when Action::DELETE_TAG
        project = target.project
        action = "<b>deleted tag</b> #{event.data} on #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
      when Action::ADD_COMMITTER
        user = target.user
        repo = target.repository
        
        action = "<b>added committer</b> #{link_to user.login, user_path(user)} to #{link_to h(repo.project.title), project_path(repo.project)}/#{link_to h(repo.name), project_repository_url(repo.project, repo)}"
      when Action::REMOVE_COMMITTER
        user = User.find_by_id(event.data.to_i)
        next unless user
        
        project = target.project
        action = "<b>removed committer</b> #{link_to user.login, user_path(user)} from #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
      when Action::COMMENT
        project = target.project
        repo = target.repository
        
        action = "<b>commented</b> on #{link_to h(project.title), project_path(project)}/#{link_to h(repo.name), project_repository_url(project, repo)}"
        body = truncate(h(target.body), 100)
      when Action::REQUEST_MERGE
        source_repository = target.source_repository
        project = source_repository.project
        target_repository = target.target_repository
        
        action = "<b>requested merge</b> #{link_to h(project.title), project_path(project)}/#{link_to h(source_repository.name), project_repository_url(project, source_repository)} to #{link_to h(project.title), project_path(project)}/#{link_to h(target_repository.name)}"
        body = "#{link_to "review", [project, target_repository, target]}<br/>#{truncate(h(target.proposal), 100)}"
      when Action::RESOLVE_MERGE_REQUEST
        source_repository = target.source_repository
        project = source_repository.project
        target_repository = target.target_repository
        
        action = "<b>resolved merge request </b>to [#{target.status_string}] from #{link_to h(project.title), project_path(project)}/#{link_to h(source_repository.name), project_repository_url(project, source_repository)}"
      when Action::UPDATE_MERGE_REQUEST
        source_repository = target.source_repository
        project = source_repository.project
        target_repository = target.target_repository
        
        action = "<b>updated merge request</b> from #{link_to h(project.title), project_path(project)}/#{link_to h(source_repository.name), project_repository_url(project, source_repository)}"
      when Action::DELETE_MERGE_REQUEST
        project = target.project
        
        action = "<b>deleted merge request</b> from #{link_to h(project.title), project_path(project)}/#{link_to h(target.name), project_repository_url(project, target)}"
    end
      
    [action, body]
  end
end
