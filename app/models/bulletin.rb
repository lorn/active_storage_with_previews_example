class Bulletin < ApplicationRecord
  has_one_attached :attachment, acl: :public
end
