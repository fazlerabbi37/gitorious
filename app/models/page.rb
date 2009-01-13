#--
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class Page
  class UserNotSetError < StandardError; end
  
  DEFAULT_FORMAT = "textile"
  
  def self.find(name, repo, format = DEFAULT_FORMAT)
    fullname = "#{name}.#{format}"
    blob = find_or_create_blob(fullname, repo)
    new(fullname, blob, repo)
  end
  
  def self.find_or_create_blob(fullname, repo)
    if blob = repo.tree/fullname
      return blob
    else
      Grit::Blob.create(repo, :name => fullname, :data => '')
    end
  end
  
  def initialize(name, blob, repo)
    @name = name
    @blob = blob
    @repo = repo
  end
  attr_accessor :user, :name
  
  def content
    @content ||= @blob.data
  end
  
  def content=(new_content)
    @content = new_content
  end
  
  def new?
    @blob.id.nil?
  end
  
  def new_record?
    # always false as a easy hack around rails' form handling
    false 
  end
  
  def to_param
    title
  end
  
  def title
    name.sub(/\.#{DEFAULT_FORMAT}$/, "")
  end
  
  def reload
    @blob = @repo.tree/@name
  end
  
  def save
    raise UserNotSetError unless user
    actor = user.to_grit_actor
    index = @repo.index
    index.add(@name, @content)
    msg = new? ? "Created #{@name}" : "Updated #{@name}"
    if head = @repo.commit("HEAD")
      parents = Array(index.read_tree(head.tree.id)).map{|h| h.id }
    else
      parents = []
    end
    index.commit(msg, parents, actor)
  end
end
