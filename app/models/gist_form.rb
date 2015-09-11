class GistForm
  attr_accessor :description, :file_name, :file_contents

  include ActiveModel::Model

  validates :description, :file_name, :file_contents, presence: true
end
